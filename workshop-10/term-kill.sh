#bash!

usage() {
    echo "Usage: $0 [username@hostname] --session <session_name>"
    echo "This script is a wrapper for the tmux kill-session command."
    echo "The script first tests the SSH connection before running the main command."
    echo "If --session option is specified, only the tmux session with that name will be killed."
    echo "If --session option is not specified all the existing tmux sessions to be killed."
    exit 1
}

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --session)
            session="$2"
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

    echo "Testing SSH connection..."
    ssh -o TCPKeepAlive=no -o BatchMode=yes -o ConnectTimeout=5 "$user_host" exit
    if [ $? -ne 0 ]; then
        echo "Error: Failed to connect to the remote server. Please check your credentials and network connection."
        exit 1
    fi
    echo "ssh connection test successful."

fi




if [ -z "$session" ]; then
    echo "killing all tmux sessions on the remote server..."
    command="tmux kill-server"

    exit_status=$?
else
    echo "killing tmux named session '$session' on the remote server..."
    command="tmux kill-session -t '$session'"

    exit_status=$?
fi

if [ -n "$user_host" ]; then
  ssh -o TCPKeepAlive=no -t "$user_host" "$command"
else
  eval "$command"
fi

exit_status=$?
if [ $exit_status -ne 0 ]; then
  echo "Error: One or more commands failed to execute. Please check the environment and configuration."
else
    echo "Success."
fi

exit $exit_status