# Etag should always be quoted - in XML as well as headers...
# handle Content-MD5 for IO stream objects too...
using AWS.Crypto
using libCURL.HTTPC
using LibExpat
using Calendar

include("s3_types.jl")

macro req_n_process(resp_obj_type)
    quote
        s3_resp = do_request(env, ro)
        if (isa(s3_resp.obj, String) &&  (length(s3_resp.obj) > 0))
            s3_resp.pd = xp_parse(s3_resp.obj)
            s3_resp.obj = $(esc(resp_obj_type))(s3_resp.pd)
        end
        s3_resp
    end
end



type S3Response
    content_length::Int  
    #Connection (open or closed) - we will not use this  
    date::String    #The date and time Amazon S3 responded, for example, Wed, 01 Mar 2009 12:00:00 GMT.
    server::String  #The name of the server that created the response.
    eTag::String
    http_code::Int

    # Common amz fields here
    delete_marker::Bool
    id_2::String
    request_id::String
    version_id::String

# all header fields
    headers::Dict
    
# All header fields    
    obj::Any
    pd::Union(ParsedData, Nothing)
    
    S3Response() = new(0, "", "", "", false, "","","",Dict{String,String,}(), nothing, nothing, nothing)
end

type RO # RequestOptions
    verb::Symbol                  # HTTP verb
    bkt::String                   # bucket
    key::String                   # object id typically  
    sub_res::Vector{Tuple}
    http_hdrs::Vector{Tuple}
    amz_hdrs::Vector{Tuple}
    cont_typ::String
    body::String
    istream::Any
    ostream::Any
    
    RO() = new(:GET, "", "", [], [], [], "", "", nothing, nothing)
    RO(verb, bkt, key) = new(verb, bkt, key, [], [], [], "", "", nothing, nothing)
end


function list_all_buckets(env::AWSEnv)
    ro = RO(:GET, "", "")
    @req_n_process(ListAllMyBucketsResult)
end 


function del_bkt(env::AWSEnv, bkt::String)
    ro = RO(:DELETE, bkt, "")
    
    s3_resp = do_request(env, ro)
    s3_resp
end

function del_bkt_cors(env::AWSEnv, bkt::String) 
    ro = RO(:DELETE, bkt, "")
    ro.sub_res={("cors", "")}
    
    s3_resp = do_request(env, ro)
    s3_resp
end

function del_bkt_lifecycle(env::AWSEnv, bkt::String) 
    ro = RO(:DELETE, bkt, "")
    ro.sub_res={("lifecycle", "")}
    
    s3_resp = do_request(env, ro)
    s3_resp
end


function del_bkt_policy(env::AWSEnv, bkt::String) 
    ro = RO(:DELETE, bkt, "")
    ro.sub_res={("policy", "")}
    
    s3_resp = do_request(env, ro)
    s3_resp
end

function del_bkt_tagging(env::AWSEnv, bkt::String) 
    ro = RO(:DELETE, bkt, "")
    ro.sub_res={("tagging", "")}
    
    s3_resp = do_request(env, ro)
    s3_resp
end

function del_bkt_website(env::AWSEnv, bkt::String) 
    ro = RO(:DELETE, bkt, "")
    ro.sub_res={("website", "")}
    
    s3_resp = do_request(env, ro)
    s3_resp
end


function get_bkt(env::AWSEnv, bkt::String; options::GetBucketOptions=GetBucketOptions()) 
    ro = RO(:GET, bkt, "")
    ro.sub_res=get_subres(Array(Tuple,0), options)
    
    @req_n_process(ListBucketResult)
end

function get_bkt_acl(env::AWSEnv, bkt::String) 
    ro = RO(:GET, bkt, "")
    ro.sub_res={("acl", "")}
    
    @req_n_process(AccessControlPolicy)
end

function get_bkt_cors(env::AWSEnv, bkt::String) 
    ro = RO(:GET, bkt, "")
    ro.sub_res={("cors", "")}
    
    @req_n_process(CORSConfiguration)
end

function get_bkt_lifecycle(env::AWSEnv, bkt::String) 
    ro = RO(:GET, bkt, "")
    ro.sub_res={("lifecycle", "")}
    
    s3_resp = do_request(env, ro)
    s3_resp
   
end

function get_bkt_policy(env::AWSEnv, bkt::String)
    ro = RO(:GET, bkt, "")
    ro.sub_res={("policy", "")}
    
    s3_resp = do_request(env, ro)
    s3_resp
   
end

function get_bkt_location(env::AWSEnv, bkt::String) 
    ro = RO(:GET, bkt, "")
    ro.sub_res={("location", "")}
    
    @req_n_process(LocationConstraint)
end

function get_bkt_logging(env::AWSEnv, bkt::String) 
    ro = RO(:GET, bkt, "")
    ro.sub_res={("logging", "")}
    
    @req_n_process(BucketLoggingStatus)
end

function get_bkt_notification(env::AWSEnv, bkt::String) 
    ro = RO(:GET, bkt, "")
    ro.sub_res={("notification", "")}
    
    @req_n_process(NotificationConfiguration)
end

function get_bkt_tagging(env::AWSEnv, bkt::String) 
    ro = RO(:GET, bkt, "")
    ro.sub_res={("tagging", "")}
    
    @req_n_process(Tagging)

end


function get_bkt_object_versions(env::AWSEnv, bkt::String; options::GetBucketObjectVersionsOptions=GetBucketObjectVersionsOptions())
    ro = RO(:GET, bkt, "")
    ro.sub_res=get_subres({("versions", "")}, options) 
    
    @req_n_process(ListVersionsResult)
end

function get_bkt_request_payment(env::AWSEnv, bkt::String) 
    ro = RO(:GET, bkt, "")
    ro.sub_res={("requestPayment", "")}
    
    @req_n_process(RequestPaymentConfiguration)
end

function get_bkt_versioning(env::AWSEnv, bkt::String)
    ro = RO(:GET, bkt, "")
    ro.sub_res={("versioning", "")}
    
    @req_n_process(VersioningConfiguration)
end

function get_bkt_website(env::AWSEnv, bkt::String)
    ro = RO(:GET, bkt, "")
    ro.sub_res={("website", "")}
    
    s3_resp = do_request(env, ro)
    s3_resp
end 

function test_bkt(env::AWSEnv, bkt::String)
    ro = RO(:HEAD, bkt, "")
    
    s3_resp = do_request(env, ro)
    s3_resp
end


function get_bkt_multipart_uploads(env::AWSEnv, bkt::String; options::GetBucketUploadsOptions=GetBucketUploadsOptions())
    ro = RO(:GET, bkt, "")
    ro.sub_res=get_subres({("uploads", "")}, options) 
    
    @req_n_process(ListMultipartUploadsResult)
end





function create_bkt(env::AWSEnv, bkt::String; acl::Union(S3_ACL, Nothing)=nothing, config::Union(CreateBucketConfiguration, Nothing)=nothing)
    ro = RO(:PUT, bkt, "")
    if isa(acl, AccessControlPolicy)
        ro.amz_hdrs = amz_headers(Array(Tuple,0), acl)
    end
    if (config != nothing)
        ro.body = xml(config)
    end
    
    s3_resp = do_request(env, ro)
    s3_resp
end


function set_bkt_acl(env::AWSEnv, bkt::String, acl::Union(AccessControlPolicy, S3_ACL))
    ro = RO(:PUT, bkt, "")
    ro.sub_res={("acl", "")}
    if isa(acl, AccessControlPolicy)
        ro.body = xml(acl)
    else
        ro.amz_hdrs = amz_headers(Array(Tuple,0), acl)
    end
    
    s3_resp = do_request(env, ro)
    s3_resp
end

function set_bkt_cors(env::AWSEnv, bkt::String, cors::CORSConfiguration)
    ro = RO(:PUT, bkt, "")
    ro.sub_res = {("cors", "")} 
    ro.body = xml(cors)
    
    s3_resp = do_request(env, ro)
    s3_resp
end

#TODO : Create LifecycleCongig type
function set_bkt_lifecycle(env::AWSEnv, bkt::String, lifecycleconfig::String)
    ro = RO(:PUT, bkt, "")
    ro.sub_res = {("lifecycle", "")} 
    ro.body = lifecycleconfig
    
    s3_resp = do_request(env, ro)
    s3_resp

end

function set_bkt_policy(env::AWSEnv, bkt::String, policy_json::String) 
    ro = RO(:PUT, bkt, "")
    ro.sub_res = {("policy", "")} 
    ro.body = policy_json
    
    s3_resp = do_request(env, ro)
    s3_resp
end

function set_bkt_logging(env::AWSEnv, bkt::String, logging::BucketLoggingStatus)
    ro = RO(:PUT, bkt, "")
    ro.sub_res = {("logging", "")} 
    ro.body = xml(logging)
    
    s3_resp = do_request(env, ro)
    s3_resp
end



function set_bkt_notification(env::AWSEnv, bkt::String, notif::NotificationConfiguration)
    ro = RO(:PUT, bkt, "")
    ro.sub_res = {("notification", "")} 
    ro.body = xml(notif)
    
    s3_resp = do_request(env, ro)
    s3_resp
end


function set_bkt_tagging(env::AWSEnv, bkt::String, tagging::Tagging) 
    ro = RO(:PUT, bkt, "")
    ro.sub_res = {("tagging", "")} 
    ro.body = xml(tagging)
    
    s3_resp = do_request(env, ro)
    s3_resp
end

function set_bkt_request_payment(env::AWSEnv, bkt::String, pay::RequestPaymentConfiguration) 
    ro = RO(:PUT, bkt, "")
    ro.sub_res = {("requestPayment", "")} 
    ro.body = xml(pay)
    
    s3_resp = do_request(env, ro)
    s3_resp
end

function set_bkt_versioning(env::AWSEnv, bkt::String, config::VersioningConfiguration; mfa::String="")
    ro = RO(:PUT, bkt, "")
    ro.sub_res = {("versioning", "")} 
    ro.body = xml(config)
    if (mfa != "") ro.amz_hdrs = {("mfa", mfa)} end
    
    s3_resp = do_request(env, ro)
    s3_resp
end

#TODO: Define WebsiteConfiguration as a type and use that....
function set_bkt_website(env::AWSEnv, bkt::String, websiteconfig::String) 
    ro = RO(:PUT, bkt, "")
    ro.sub_res = {("website", "")} 
    ro.body = websiteconfig
    
    s3_resp = do_request(env, ro)
    s3_resp
end

######################################
### OPERATIONS ON OBJECTS
######################################

function del_object(env::AWSEnv, bkt::String, key::String; version_id::String="", mfa::String="") 
    ro = RO(:DELETE, bkt, key)
    if (version_id != "") ro.sub_res = {("versionId", version_id)} end
    if (mfa != "") ro.amz_hdrs = {("mfa", mfa)} end
    
    s3_resp = do_request(env, ro)
    s3_resp
end

function del_object_multi(env::AWSEnv, bkt::String, delset::DeleteObjectsType; mfa::String="")
    ro = RO(:POST, bkt, key)
    ro.sub_res = {("delete", "")}
    ro.body= xml(delset)
    if (mfa != "") ro.amz_hdrs = {("mfa", mfa)} end
    
    @req_n_process(DeleteResult)
end


function get_object(env::AWSEnv, bkt::String, key::String; options::GetObjectOptions=GetObjectOptions(), out::Union(IO, String, Nothing)=nothing, version_id::String="")
    ro = RO(:GET, bkt, key)
    ro.sub_res = Array(Tuple,0)
    
    if (version_id != "") push!(ro.sub_res, ("versionId", version_id)) end
    ro.sub_res = query_params(ro.sub_res, options)
    
    ro.http_hdrs = http_headers(Array(Tuple,0), options)
    ro.ostream = out

    s3_resp = do_request(env, ro)
    s3_resp
end

function get_object_acl(env::AWSEnv, bkt::String, key::String; version_id::String="")
    ro = RO(:GET, bkt, key)
    ro.sub_res={("acl", "")}
    if (version_id != "") push!(ro.sub_res, ("versionId", version_id)) end
    
    @req_n_process(AccessControlPolicy)
end

function get_object_torrent(env::AWSEnv, bkt::String, key::String, out::Union(IO, String)) # out is either an IOStream or a filename
    ro = RO(:GET, bkt, key)
    ro.sub_res={("torrent","")}
    ro.ostream = out
    
    s3_resp = do_request(env, ro)
    s3_resp
end

function describe_object(env::AWSEnv, bkt::String, key::String; options::GetObjectOptions=GetObjectOptions(), version_id::String="")
    ro = RO(:HEAD, bkt, key)
    ro.http_hdrs = http_headers(options)
    if (version_id != "") ro.sub_res={("versionId", version_id)} end

    s3_resp = do_request(env, ro)
    s3_resp
end

function test_object(env::AWSEnv, bkt::String, key::String, origin::String, acc_ctrl_req_method::String; acc_ctrl_req_hdrs::Union(String, Nothing)=nothing)
    ro = RO(:OPTIONS, bkt, key)
    ro.http_hdrs = {("Origin", origin), ("Access-Control-Request-Method",acc_ctrl_req_method)}
    if headers != nothing
        push!(ro.http_hdrs, ("Access-Control-Request-Headers", acc_ctrl_req_hdrs))
    end

    s3_resp = do_request(env, ro)
    s3_resp
end

#post_object, a different version of put_object is not supported


function restore_object(env::AWSEnv, bkt::String, key::String, days::Int)
    # TODO qp = "restore"
    # convert days to RestoreRequest
    ro = RO(:POST, bkt, key)

    ro.sub_res={("restore", "")}
    ro.body = "<RestoreRequest xmlns=\"http://s3.amazonaws.com/doc/2006-3-01\"><Days>$(days)</Days></RestoreRequest>"
    
    s3_resp = do_request(env, ro)
    s3_resp
end


function put_object(env::AWSEnv, bkt::String, key::String, data::Union(IOStream, String, Tuple); content_type="", options::PutObjectOptions=PutObjectOptions(), version_id::String="")
    ro = RO(:PUT, bkt, key)
    
    ro.amz_hdrs = amz_headers(Array(Tuple,0), options)
    ro.http_hdrs = http_headers(Array(Tuple, 0), options)
    if (content_type != "") ro.content_type = content_type end
    
    if isa(data, String) 
        ro.body = data
    elseif isa(data, IO) 
        ro.istream = data
    elseif (isa(data, Tuple) && data[1] == :file)
        ro.istream = data[2]
    else
        error("Nothing to upload")
    end

    if (version_id != "") ro.sub_res={("versionId", version_id)} end
    
    s3_resp = do_request(env, ro)
    s3_resp
end

function put_object_acl(env::AWSEnv, bkt::String, key::String, acl::Union(AccessControlPolicy, S3_ACL))
    ro = RO(:PUT, bkt, key)
    ro.sub_res={("acl", "")}
    if isa(acl, AccessControlPolicy)
        ro.body = xml(acl)
    else
        ro.amz_hdrs = amz_headers(Array(Tuple,0), acl)
    end
    
    s3_resp = do_request(env, ro)
    s3_resp
end


function copy_object(env::AWSEnv, dest_bkt::String, dest_key::String, options::CopyObjectOptions, version_id::String="")
    ro = RO(:PUT, dest_bkt, dest_key)
    ro.amz_hdrs = amz_headers(Array(Tuple,0), options)
    if (version_id != "")
        ro.sub_res={("versionId", version_id)}
    end
    
    @req_n_process(CopyObjectResult)
end

function initiate_multipart_upload(env::AWSEnv, bkt::String, key::String; content_type="", options::PutObjectOptions=PutObjectOptions())
    ro = RO(:POST, bkt, key)
    ro.amz_hdrs = amz_headers(Array(Tuple,0), options)
    ro.http_hdrs = http_headers(Array(Tuple, 0), options)
    if (content_type != "") ro.content_type = content_type end
    ro.sub_res={("uploads", "")}

    @req_n_process(InitiateMultipartUploadResult)
end

function upload_part(env::AWSEnv, bkt::String, key::String, part_number::String, upload_id::String, data::Union(IOStream, String, Tuple))
    ro = RO(:PUT, bkt, key)
    ro.sub_res = {("partNumber", "$(part_number)"), ("uploadId", "$(upload_id)")}
    
    if isa(data, String) 
        ro.body = data
    elseif isa(data, IO) 
        ro.istream = data
    elseif (isa(data, Tuple) && data[1] == :file)
        ro.istream = data[2]
    else
        error("Nothing to upload")
    end
    
    s3_resp = do_request(env, ro)
    s3_resp
    
end

function copy_upload_part(env::AWSEnv, bkt::String, key::String, part_number::String, upload_id::String, options::CopyUploadPartOptions)
    ro = RO(:PUT, bkt, key)
    ro.sub_res = {("partNumber", "$(part_number)"), ("uploadId", "$(upload_id)")}
    ro.amz_hdrs = amz_headers(options)
    
    @req_n_process(CopyPartResult)
end


function complete_multipart_upload(env::AWSEnv, bkt::String, key::String, upload_id::String, part_ids::Vector{S3PartTag})
    ro = RO(:POST, bkt, key)
    ro.sub_res = {("uploadId", "$(upload_id)")}
   
    ro.body = xml("CompleteMultipartUpload", part_ids)
    
    @req_n_process(CompleteMultipartUploadResult)
end


function abort_multipart_upload(env::AWSEnv, bkt::String, key::String, upload_id::String)
    ro = RO(:DELETE, bkt, key)
    ro.sub_res = {("uploadId", "$(upload_id)")}
    
    s3_resp = do_request(env, ro)
    s3_resp
end

function list_upload_parts(env::AWSEnv, bkt::String, key::String, 
    upload_id::String; 
    max_parts::Union(Int, Nothing)=nothing, 
    part_number​_marker::Union(Int, Nothing)=nothing)
    
    ro = RO(:GET, bkt, key)
    ro.sub_res = {("uploadId", "$(upload_id)"), ("max-parts", "$max_parts"), ("part-number​-marker", "$part_number​_marker")}
    
    @req_n_process(ListPartsResult)
end

function do_request(env::AWSEnv, ro::RO)
    http_resp = do_http(ro)
    
    s3_resp = S3Response()
    
    s3_resp.http_code = http_resp.http_code
    cl_s = get(http_resp.headers, "Content-Length", "") 
    if cl_s != ""
        s3_resp.content_length = int(cl_s)
    end
    s3_resp.date = get(http_resp.headers, "Date", "") 
    s3_resp.eTag = get(http_resp.headers, "ETag", "") 
    s3_resp.server = get(http_resp.headers, "Server", "") 
    
    s3_resp.delete_marker = lowercase(get(http_resp.headers, "x-amz-delete-marker", "false")) == "true" ? true : false 
    s3_resp.id_2 = get(http_resp.headers, "x-amz-id-2", "") 
    s3_resp.request_id = get(http_resp.headers, "x-amz-request-id", "") 
    s3_resp.version_id = get(http_resp.headers, "x-amz-version-id", "") 

    s3_resp.headers = http_resp.headers

    if (http_resp.http_code > 299)
        if  (search(Base.get(http_resp.headers, "Content-Type", ""), "/xml") != 0:-1) &&
            (s3_resp.content_length > 0) &&
            (http_resp.body != "")
            s3_resp.pd = xp_parse(http_resp.body)
            if s3_resp.pd.name == "Error"
                s3_resp.obj = S3Error(s3_resp.pd) 
            end
        end
    else
        s3_resp.obj = http_resp.body
    end
    
    s3_resp
end

function do_http(env::AWSEnv, ro::RO)
    if ro.body != nothing
        digest = zeros(Uint8, 16)
        MD5(body, length(body), digest)
        md5 = bytestring(Codecs.encode(Base64, Crypto.md5(ro.body)))
    elseif isa(ro.istream, IO)
        # Read the entire istream to get the MD5 of the same.
        md5 = bytestring(Codecs.encode(Base64, Crypto.md5(ro.istream)))
        seekstart(ro.istream)
    elseif isa(ro.istream, String)
        # The file will be read twice (once to get the MD5 and once while sending - no other way?
        md5 = bytestring(Codecs.encode(Base64, Crypto.md5_file(ro.istream)))
    else
        md5 = ""
    end
    
    (new_amz_hdrs, full_path, s_b64) = canonicalize_and_sign(env, ro, md5)
    
    all_hdrs = new_amz_hdrs
    (md5 != "") ? push!(all_hdrs, {("Content-MD5", md5)}) : nothing
    (cont_typ != "") ? push!(all_hdrs, {("Content-Type", cont_typ)}) : nothing

    # Remove Content-MD5 and Expect headers from the passed http_hdrs
    for (name, value) in ro.http_hdrs
        lname = lowercase(strip(name))
        if (lname != "content-md5") && (lname != "expect") && (lname != "content-type")
            push!(all_hdrs, (name, value))
        elseif (lname == "content-type") && (ro.cont_typ == "")
            # If content type has been set as part of RO, it will be used.
            push!(all_hdrs, (name, value))
        end
    end

    push!(all_hdrs, {("Authorization",  "AWS " * env.aws_id * ":" * s_b64)})
    
    url = "https://s3.amazonaws.com" * full_path
    
    http_options = RequestOptions(headers=all_hdrs, ostream=ro.ostream, request_timeout=env.timeout)
    if ro.verb == :GET
        http_resp = HTTPC.get(url, http_options)
    elseif (ro.verb == :PUT) || (ro.verb == :POST)
        senddata = (ro.body != nothing) ? ro.body :
                   isa(ro.istream, IO) ? ro.istream :
                   isa(ro.istream, String) ? (file: ro.istream) :
                   error("Must specify either a body or istream for PUT/POST")
    
        if (ro.verb == :PUT)
            http_resp = HTTPC.put(url, senddata, http_options)
        else 
            http_resp = HTTPC.post(url, senddata, http_options)
        end
        
    elseif ro.verb == :DELETE
        http_resp = HTTPC.delete(url, http_options)
        
    elseif ro.verb == :HEAD
        http_resp = HTTPC.head(url, http_options)
    
    else
        error("Unknown HTTP verb $verb")
    end
    
    return http_resp
end
        
        
function canonicalize_and_sign(env::AWSEnv, ro::RO, md5::String)
    new_amz_hdrs, amz_hdrs_str = get_canon_amz_headers(ro.amz_hdrs)
    full_path = get_canonicalized_resource(ro)

    str2sign = string(ro.verb) * "\n" *
    md5 * "\n" *
    ro.cont_typ * "\n" * "\n" * # Using x-amz-date instead of Date.
    amz_hdrs_str * full_path
    
    s_raw = Crypto.hmacsha1_digest(str2sign, env.aws_seckey)
    s_b64 = bytestring(Codecs.encode(Base64, s_raw))
    
    return new_amz_hdrs, full_path, s_b64
end

function get_canonicalized_resource(ro::RO)
    if length(ro.bkt) > 0
        part1 = (beginswith(ro.bkt, "/") ? "" : "/") * ro.bkt * 
        (beginswith(ro.key, "/") ? "" : "/") * ro.key 
    else
        part1 = "/"
    end
    
    if length(ro.sub_res) > 0
        return part1 * "?" * HTTPC.urlencode_query_params(sort(ro.sub_res))
    else
        return part1
    end
end

function get_canon_amz_headers(headers::Vector{Tuple})
    if length(headers) == 0 return end
    
    lcase = [(lowercase(strip(k)), v) for (k,v) in headers]
    if contains(lcase, "x-amz-date")
        delete!(lcase, "x-amz-date")
    end
    
    lcase["x-amz-date"] = rfc1123_date(Calendar.now())
    
    reduced = Dict(String, String)()
    for (k,v) in lcase
        if beginswith("x-amz-", k)
            new_v = strip(replace(v, "\n", ' '))
            if contains(reduced, k)
                ev = reduced[k]
                reduced[k] = ev * "," * new_v
            else
                reduced[k] = new_v
            end
        end
    end

    # Use the sorted one in the final request too since the order of 'values' 
    sorted = sort(collect(reduced))
    canon_hdr_str = reduce((acc,elem) -> begin (k,v) = elem; acc * k * ":" * v * "\n" end, "", sorted) 
    
    return sorted, canon_hdr_str
end

function rfc1123_date(d::CalendarTime)
    format("EEE, dd MMM yyyy hh:mm:ss V", Calendar.tz(d, "UTC"))
end









