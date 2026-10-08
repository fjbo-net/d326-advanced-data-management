#!/usr/bin/env bash
# © 2026 FJBO
#
# Runs a throwaway PostgreSQL cluster inside the repository, so the project can
# be worked on without a system-wide PostgreSQL installation.
#
# Requires the PostgreSQL command-line tools (`initdb`, `pg_ctl`, `psql`) on the
# `PATH`, or in the directory named by `PG_BIN`.
#
# The cluster lives in `.tmp/` (ignored by Git) and is reachable only through a
# Unix socket in that directory, so it never opens a network port and never
# collides with another PostgreSQL on the machine.
#
# Usage: local-db.sh <command> [arguments]
#
#   init     Create the cluster, if it does not exist yet
#   start    Start the cluster, creating it first when needed
#   stop     Stop the cluster
#   status   Report whether the cluster is running
#   restore  Load the DVD Rental dump into a new 'dvdrental' database; takes the
#            path to the downloaded `dvdrental.zip` or to the `dvdrental.tar`
#   reset    Delete the cluster and start a new, empty one; given a dump, as for
#            `restore`, also load it, which returns 'dvdrental' to its original
#            state
#   psql     Open `psql` against the cluster; arguments are passed through
#   env      Print `export` lines so a plain `psql` reaches the cluster:
#            eval "$(scripts/dev/local-db.sh env)"

set -euo pipefail

RepoRoot="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DataDirectory="$RepoRoot/.tmp/pgdata"
SocketDirectory="$RepoRoot/.tmp/pgsocket"
LogFile="$RepoRoot/.tmp/postgres.log"

DatabaseName="dvdrental"
SuperUser="postgres"

export PGHOST="$SocketDirectory"
export PGPORT="${PGPORT:-5432}"
export PGUSER="$SuperUser"


# Runs a PostgreSQL tool from `PG_BIN` when set, otherwise from the `PATH`
pg() {
	local Tool="$1"
	shift

	if [ -z "${PG_BIN:-}" ] && ! command -v "$Tool" >/dev/null 2>&1; then
		echo "ERROR: '$Tool' was not found. Install PostgreSQL or set PG_BIN." >&2
		exit 1
	fi

	"${PG_BIN:+$PG_BIN/}$Tool" "$@"
}

is_running() {
	pg pg_ctl status -D "$DataDirectory" >/dev/null 2>&1
}


init() {
	if [ -f "$DataDirectory/PG_VERSION" ]; then
		echo "Cluster already exists: '$DataDirectory'"
		return
	fi

	echo "Creating cluster in '$DataDirectory'..."
	mkdir -p "$(dirname "$DataDirectory")"
	pg initdb -D "$DataDirectory" -U "$SuperUser" --auth=trust --encoding=UTF8 --no-instructions >/dev/null
	echo "SUCCESS: Cluster created"
}

start() {
	init

	if is_running; then
		echo "Cluster is already running"
		return
	fi

	echo "Starting cluster..."
	mkdir -p -m 700 "$SocketDirectory"
	pg pg_ctl start -D "$DataDirectory" -l "$LogFile" -w \
		-o "-k '$SocketDirectory' -c listen_addresses=''" >/dev/null
	echo "SUCCESS: Cluster is running. Log: '$LogFile'"
}

stop() {
	if ! is_running; then
		echo "Cluster is not running"
		return
	fi

	echo "Stopping cluster..."
	pg pg_ctl stop -D "$DataDirectory" -m fast -w >/dev/null
	echo "SUCCESS: Cluster stopped"
}

status() {
	pg pg_ctl status -D "$DataDirectory"
}

restore() {
	local DumpFile="${1:-}"

	if [ ! -f "$DumpFile" ]; then
		echo "ERROR: Dump file not found: '$DumpFile'" >&2
		echo "Usage: local-db.sh restore <dvdrental.zip|dvdrental.tar>" >&2
		exit 1
	fi

	start

	local Exists
	Exists="$(pg psql -d postgres -Atc "SELECT 1 FROM pg_database WHERE datname = '$DatabaseName'")"
	if [ "$Exists" = "1" ]; then
		echo "ERROR: Database '$DatabaseName' already exists. To start over, run:" >&2
		echo "  local-db.sh psql -d postgres -c 'DROP DATABASE $DatabaseName'" >&2
		exit 1
	fi

	# The sample database is distributed as a zip holding a tar-format dump
	local DumpPath="$DumpFile"
	if [[ "$DumpFile" == *.zip ]]; then
		echo "Extracting '$DumpFile'..."
		ExtractDirectory="$(mktemp -d "$RepoRoot/.tmp/restore.XXXXXX")"
		trap 'rm -rf "$ExtractDirectory"' EXIT
		if ! unzip -q -o "$DumpFile" -d "$ExtractDirectory" 2>/dev/null \
			&& ! python3 -m zipfile -e "$DumpFile" "$ExtractDirectory" 2>/dev/null; then
			echo "ERROR: Could not extract '$DumpFile'. Install 'unzip' or 'python3', or extract the '.tar' and pass that instead" >&2
			exit 1
		fi
		DumpPath="$(find "$ExtractDirectory" -name '*.tar' | head -n 1)"

		if [ -z "$DumpPath" ]; then
			echo "ERROR: No '.tar' dump found inside '$DumpFile'" >&2
			exit 1
		fi
	fi

	echo "Restoring '$DatabaseName' from '$DumpPath'..."
	pg createdb "$DatabaseName"
	if ! pg pg_restore -d "$DatabaseName" "$DumpPath"; then
		pg dropdb "$DatabaseName"
		echo "ERROR: Restore failed; database '$DatabaseName' was removed" >&2
		exit 1
	fi
	echo "SUCCESS: Database '$DatabaseName' restored"
}

reset_cluster() {
	local DumpFile="${1:-}"

	# Check before deleting anything, so a mistyped path cannot cost the data
	if [ -n "$DumpFile" ] && [ ! -f "$DumpFile" ]; then
		echo "ERROR: Dump file not found: '$DumpFile'" >&2
		exit 1
	fi

	stop

	# Only a real cluster is deleted, never an arbitrary directory
	if [ -f "$DataDirectory/PG_VERSION" ]; then
		echo "Deleting cluster '$DataDirectory'..."
		rm -rf "$DataDirectory"
	fi
	rm -f "$LogFile"

	if [ -n "$DumpFile" ]; then
		restore "$DumpFile"
	else
		start
	fi
}

open_psql() {
	PGDATABASE="${PGDATABASE:-$DatabaseName}" pg psql "$@"
}

print_env() {
	printf 'export PGHOST=%q PGPORT=%q PGUSER=%q\n' "$PGHOST" "$PGPORT" "$PGUSER"
}

usage() {
	sed -n '/^# Usage:/,/^$/p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}


Command="${1:-}"
[ "$#" -gt 0 ] && shift

case "$Command" in
	init) init ;;
	start) start ;;
	stop) stop ;;
	status) status ;;
	restore) restore "$@" ;;
	reset) reset_cluster "$@" ;;
	psql) open_psql "$@" ;;
	env) print_env ;;
	*)
		usage >&2
		exit 1
		;;
esac
