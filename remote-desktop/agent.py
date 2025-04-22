import json
import subprocess
from http.server import BaseHTTPRequestHandler, HTTPServer

class RequestHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/restart-vnc-session':
            try:
                subprocess.Popen("vncserver -kill :1 && vncserver :1", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                self.respond(200, {})
            except Exception as e:
                self.respond(500, {"error": str(e)})
    
    def do_POST(self):
        if self.path == '/clipboard-paste':
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length).decode("utf-8")
            
            try:
                data = json.loads(post_data)
                clipboard_content = data.get("content")
                if not clipboard_content:
                    self.respond(400, {"error": "Missing clipboard content"})
                    return
                
                clipboard_content = clipboard_content.replace("'", "'\\''")
                command = "echo -n '" + clipboard_content + "' | xclip -selection clipboard &"
                subprocess.Popen(command, shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                
                self.respond(200, {})
            except Exception as e:
                self.respond(500, {"error": str(e)})
    
    def respond(self, status_code, response_data):
        response_json = json.dumps(response_data)
        self.send_response(status_code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(response_json)))
        self.end_headers()
        self.wfile.write(response_json.encode("utf-8"))

if __name__ == '__main__':
    server_address = ('0.0.0.0', 5000)
    httpd = HTTPServer(server_address, RequestHandler)
    print("Server running on port 5000...")
    httpd.serve_forever()
