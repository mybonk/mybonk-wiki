#bash!
usage() {
  echo "Usage: $0 [username@hostname] [--remote-dir <remote_directory>] [--help]"
  echo "This script is a wrapper for the following command:"
  echo "ssh -o TCPKeepAlive=no -t username@hostname \"cd '$remote_directory' ; tmuxinator -p tmuxinator.yml\""
  echo "Options:"
  echo " username@hostname Specifies the remote host to connect to. If not provided, the command will be executed locally."
  echo " --remote-dir <remote_directory> Specifies the remote directory to use. If not provided, the current directory (.) is used."
  echo " --help Displays this help message and exits."
  exit 1
}

check_tmuxinator() {
  if ! command -v tmuxinator &> /dev/null; then
    echo "$0 requires tmuxinator to be installed on the target machine."
    exit 1
  fi
}

remote_directory="."
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    --remote-dir)
      remote_directory="$2"
      shift # past argument
      shift # past value
      ;;
    --help)
      usage
      ;;
    *)
      user_host="$1"
      shift # past argument
      ;;
  esac
done

if [ -z "$user_host" ]; then
  hostname="localhost"
else
  hostname=$(echo "$user_host" | cut -d'@' -f2)
fi

check_tmuxinator

echo "Constructed the following command that will be run on $hostname:"
session_name=${hostname//./''} # Remove the potential dots in the hostname as they are a problem in tmux for session names.
session_name=${session_name: -8} # Shorten the session name to the last 8 characters.

command="cd '$remote_directory' && tmuxinator local && sh --login"
echo $command

if [ -n "$user_host" ]; then
  ssh -o TCPKeepAlive=no -t "$user_host" "$command"
else
  eval "$command"
fi

exit_status=$?
if [ $exit_status -ne 0 ]; then
  echo "Error: One or more commands failed to execute. Please check the environment and configuration."
  exit $exit_status
fi
