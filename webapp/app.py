from flask import Flask, request, send_from_directory
import os
import json

app = Flask(__name__)

@app.route("/filetransfer/file")
def return_file():
    fileId = request.headers.get('x-ms-file-id')

    files = os.listdir('./files')

    if(int(fileId) <= len(files)):
        return send_from_directory('./files', files[int(fileId)-1])

@app.route("/filetransfer/files")
def return_list():
    returnme = { 
        "fileListing": {
            "Receiver": "hello@goodbye.com",
            "Sender": "goodbye@hello.com",
            "Files": []
        }
    }

    count = 1
    for f in os.listdir('./files'):
        newEntry = {
            "id": f"{count:05}",
            "name": f,
            "size": os.path.getsize("./files/{}".format(f))
        }
        
        returnme['fileListing']['Files'].append(newEntry)
        count += 1

    return json.dumps(returnme)