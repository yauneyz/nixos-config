{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    go
    protobuf # protoc compiler (shared with python tooling)
    protoc-gen-go
    protoc-gen-go-grpc
  ];
}
