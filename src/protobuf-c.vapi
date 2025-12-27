[CCode (cprefix = "ProtobufC", lower_case_cprefix = "protobuf_c_")]
namespace ProtobufC {
    [CCode (cname = "ProtobufCMessage")]
    public class Message {
    }

    [CCode (cname = "ProtobufCService")]
    public class Service {
    }

    // Add more as needed
}

[CCode (cheader_filename = "auth/auth.pb-c.h")]
namespace Auth {
    [CCode (cname = "Auth__RegisterRequest")]
    public struct RegisterRequest {
        ProtobufC.Message base;
        public string username;
        public string password;
        public string security_key;
    }

    [CCode (cname = "Auth__RegisterResponse")]
    public struct RegisterResponse {
        ProtobufC.Message base;
        public string token;
    }

    [CCode (cname = "Auth__LoginRequest")]
    public struct LoginRequest {
        ProtobufC.Message base;
        public string username;
        public string password;
    }

    [CCode (cname = "Auth__LoginResponse")]
    public struct LoginResponse {
        ProtobufC.Message base;
        public string token;
    }

    [CCode (cname = "auth__register_request__init")]
    public static void register_request_init (RegisterRequest* message);

    [CCode (cname = "auth__login_request__init")]
    public static void login_request_init (LoginRequest* message);

    // Add more methods as needed
}