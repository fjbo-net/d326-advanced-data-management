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
	psql) open_psql "$@" ;;
	env) print_env ;;
	*)
		usage >&2
		exit 1
		;;
esac
