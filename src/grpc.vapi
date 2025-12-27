[CCode (cheader_filename = "grpc++/grpc++.h")]
namespace Grpc {
    [CCode (cname = "grpc::Channel")]
    public class Channel {
    }

    [CCode (cname = "grpc::CreateChannel")]
    public Channel create_channel (string address, void* credentials);

    // Add more as needed
}