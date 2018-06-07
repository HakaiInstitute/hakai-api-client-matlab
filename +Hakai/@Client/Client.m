classdef Client

% ============= Public =============
  properties (Access = public)
    api_root;
    credentials;
  end

  methods (Access = public)

    % Constructor
    function obj = Client(val)
       if nargin == 0
        obj.api_root = "https://hecate.hakai.org/api";
       else
        obj.api_root = val;
       end
       obj.authorization_base_url = sprintf('%s/auth/oauth2', obj.api_root);
       obj.token_url = sprintf('%s/auth/oauth2/token', obj.api_root);

       cred = obj.try_to_load_credentials();

       if cred
         obj.credentials = cred;
       else
         cred = obj.get_credentials_from_web();
         obj.save_credentials(cred);
         obj.credentials = cred;
       end
    end


    function r = get(obj,endpointUrl)
       % get data from endpointUrl
       token = sprintf('%s %s', obj.credentials.token_type, obj.credentials.access_token);
       options = weboptions('Authorization',token);
       data = webread(endpointUrl,options);

       %return in approprit format
       r = jsondecode(data);
    end

    function r = remove_old_credentials(obj)
      if exist(obj.credentials_file, 'file') == 2
        r = delete(obj.credentials_file);
      else
        r = false;
      end
    end

  end

% ============= Private =============
  properties (Access = private)
    client_id = '289782143400-1f4r7l823cqg8fthd31ch4ug0thpejme.apps.googleusercontent.com';
    authorization_base_url;
    token_url;
    credentials_file = GetFullPath('~/.hakai-api-credentials-matlab.mat');
  end

  methods (Access = private)

    function r = get_credentials_from_web(obj)
      % Get the user to login and get the oAuth2 code from the redirect url
      disp("Please go here and authorize:");
      disp(obj.authorization_base_url);
      redirect_response = input('\nPaste the full redirect URL here:','s');
      code = regexp(redirect_response, 'code=(.*)$', 'tokens', 'once');

      % Exchange the oAuth2 code for a jwt token
      data = jsonencode(struct('code',code));
      options = weboptions('MediaType','application/json');
      res = webwrite(obj.token_url,data,options);

      t = datetime('now');
      current_time = posixtime(t);
      cred.access_token = res.access_token;
      cred.token_type = res.token_type;
      cred.expires_in = res.expires_in;
      cred.expires_at = current_time + res.expires_in;

      r = cred;
      return
    end

    % Load credential from the credentials_file location
    function r = try_to_load_credentials(obj)
      if exist(obj.credentials_file, 'file') ~= 2
        r = false;
        return
      end

      cache = load(obj.credentials_file);
      root = cache.api_root;
      cred = cache.credentials;

      % Check api root is the same and that credentials aren't expired
      t = datetime('now');
      current_time = posixtime(t);
      same_root = obj.api_root == root;
      credentials_expired = current_time > cred.expires_at;

      if ~same_root || credentials_expired
        delete(obj.credentials_file);
        r = false;
        return
      end

      % If all is well, return the credentials
      r = cred;
      return
    end

    % Save the credentials to the credentials_file location
    function r = save_credentials(obj, cred)
      cache.api_root = obj.api_root;
      cache.credentials = cred;
      % Save the fields of structure cache as individual variables
      save(obj.credentials_file, '-struct', 'cache')
    end

  end
end
