"""Send a reply from the proxy without sending any data to the remote server."""
from mitmproxy import http


def request(flow: http.HTTPFlow) -> None:
    if 'google' in flow.request.pretty_url:
        flow.request.host = 'duckduckgo.com'
    elif 'facebook' in flow.request.pretty_url:
        flow.request.host = 'chat.linux.mama.sh'
