#!/usr/bin/env python3
import sys
import os
import json
import tempfile
import importlib.util
from subprocess import run

# Simple helper: generates Python gRPC stubs from proto and calls AuthService

def main():
    if len(sys.argv) < 5:
        print(json.dumps({"error": "usage: grpc_auth_client.py <server> <login|register> <username> <password> [security_key]"}))
        return 2
    server = sys.argv[1]
    method = sys.argv[2]
    username = sys.argv[3]
    password = sys.argv[4]
    security_key = sys.argv[5] if len(sys.argv) > 5 else ""

    repo_root = os.path.dirname(os.path.dirname(__file__))
    proto_path = os.path.join(repo_root, 'protos', 'proto', 'auth', 'auth.proto')
    if not os.path.exists(proto_path):
        print(json.dumps({"error": "auth.proto not found"}))
        return 3

    # Generate python code in temp dir
    import grpc
    try:
        from grpc_tools import protoc
    except Exception as e:
        print(json.dumps({"error": "grpc_tools not installed", "detail": str(e)}))
        return 4

    with tempfile.TemporaryDirectory() as td:
        args = [
            'protoc',
            f'--proto_path={os.path.dirname(os.path.dirname(proto_path))}',
            f'--python_out={td}',
            f'--grpc_python_out={td}',
            os.path.relpath(proto_path, start=os.path.dirname(os.path.dirname(proto_path)))
        ]
        # run protoc
        rc = protoc.main(args)
        if rc != 0:
            print(json.dumps({"error": "protoc failed", "rc": rc}))
            return 5

        # import generated modules
        sys.path.insert(0, td)
        # package path is auth.auth_pb2 etc. but protoc with our args will place files in 'auth' subdir
        try:
            spec1 = importlib.util.spec_from_file_location('auth_pb2', os.path.join(td, 'auth', 'auth_pb2.py'))
            auth_pb2 = importlib.util.module_from_spec(spec1)
            spec1.loader.exec_module(auth_pb2)

            spec2 = importlib.util.spec_from_file_location('auth_pb2_grpc', os.path.join(td, 'auth', 'auth_pb2_grpc.py'))
            auth_pb2_grpc = importlib.util.module_from_spec(spec2)
            spec2.loader.exec_module(auth_pb2_grpc)
        except Exception as e:
            print(json.dumps({"error": "import generated stubs failed", "detail": str(e)}))
            return 6

        # create channel
        try:
            channel = grpc.insecure_channel(server)
            stub = auth_pb2_grpc.AuthServiceStub(channel)
            if method == 'login':
                req = auth_pb2.LoginRequest(username=username, password=password)
                resp = stub.Login(req)
                print(json.dumps({"token": resp.token}))
                return 0
            elif method == 'register':
                req = auth_pb2.RegisterRequest(username=username, password=password, security_key=security_key)
                resp = stub.Register(req)
                print(json.dumps({"token": resp.token}))
                return 0
            else:
                print(json.dumps({"error": "unknown method"}))
                return 7
        except Exception as e:
            print(json.dumps({"error": "rpc call failed", "detail": str(e)}))
            return 8

if __name__ == '__main__':
    rc = main()
    sys.exit(rc)
