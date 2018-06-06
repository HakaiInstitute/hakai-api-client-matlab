classdef Client

% ============= Public =============
  properties (Access = public)
    api_root;
    credentials;
  end

  methods (Access = public)

    % Constructor
    function obj = Client(val)
       if isempty(val)
        obj.api_root = "https://hecate.hakai.org/api"
       else
        obj.api_root = val;
       end
       obj.authorization_base_url <- sprintf('%s/auth/oauth2', obj.api_root);
       obj.token_url <- sprintf('%s/auth/oauth2/token', api_root);
    end


    function r = get(obj,endpointUrl)
       % get data from endpointUrl
       token = sprintf("%s %s", obj.credentials.token_type, obj.credentials.access_token)
       options = weboptions('Authorization',token);
       data = webread(endpointUrl,options);

       %return in approprit format
       r = jsondecode(data);
    end

    function r = remove_old_credentials(obj)
       if exist(obj.credentials_file, 'file') == 2
         delete(obj.credentials_file);
       end
    end

  end

% ============= Private =============
  properties (Access = private)
    ***REMOVED***
    authorization_base_url;
    token_url;
    credentials_file; % = GetFullPath('~/.hakai-api-credentials-r');
  end

  methods (Access = private)

    function r = get_credentials_from_web(obj)
      % Get the user to login and get the oAuth2 code from the redirect url
      disp("Please go here and authorize:")
      disp(private$authorization_base_url)
      redirect_response = input('\nPaste the full redirect URL here:','s')
      code = regexp(redirect_response, 'code=(.*)$', 'tokens', 'once')

      % Exchange the oAuth2 code for a jwt token
      data = struct('code',code);
      options = weboptions('MediaType','application/json');
      res = webwrite(obj.token_url,data,options);
      res_body = res.parsed;

      t = datetime('now');
      current_time = posixtime(t)
      credentials = struct(
        'access_token', res_body.access_token,
        'token_type', res_body.token_type,
        'expires_in', res_body.expires_in,
        'expires_at', current_time + res_body.expires_in
      )

      r = credentials;
      return
    end

    % Load credential from the credentials_file location
    function r = try_to_load_credentials(obj)
      if exist(obj.credentials_file, 'file') != 2
        r = false;
        return
      end

      cache = load(obj.credentials_file);
      api_root = cache.api_root
      credentials = cache.credentials

      % Check api root is the same and that credentials aren''t expired
      t = datetime('now');
      current_time = posixtime(t)
      same_root = self$api_root == api_root;
      credentials_expired = current_time > credentials.expires_at;

      if(!same_root || credentials_expired){
        delete(obj.credentials_file);
        r = false;
        return
      }

      # If all is well, return the credentials
      r = credentials;
      return
    end

    % Save the credentials to the credentials_file location
    function r = save_credentials(obj, cred)
      cache = struct(
        'api_root', obj.api_root,
        'credentials', cred
      );
      save(obj.credentials_file, '-struct', cache);

      %fileID = fopen(obj.credentials_file,'w');
      %fprintf(fileID,'%s',cache);
      %fclose(fileID);
    end

  end
end
