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
       obj.authorization_base_url = sprintf('%s-client-login', obj.api_root);
       obj.token_url = sprintf('%s/auth/oauth2/token', obj.api_root);

       if ispc
         userdir= getenv('USERPROFILE');
       else
         userdir= getenv('HOME');
       end
       obj.credentials_file = fullfile(userdir, '.hakai-api-credentials-matlab.mat');

       cred = obj.try_to_load_credentials();

       if isstruct(cred)
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
       options = weboptions('HeaderFields',{'Authorization' token},'Timeout', 120);
       data = webread(endpointUrl,options);
       % webread auto converts json response to matlab struct
       r = data;
    end

    function r = remove_old_credentials(obj)
      if exist(obj.credentials_file, 'file') == 2
        delete(obj.credentials_file);
      end
      r = true;
    end

  end

% ============= Private =============
  properties (Access = private)
    ***REMOVED***
    authorization_base_url;
    token_url;
    credentials_file;
  end

  methods (Access = private)

    function r = get_credentials_from_web(obj)
      % Get the user to login and get the oAuth2 code from the redirect url
      disp("Please go here and authorize:");
      disp(obj.authorization_base_url);
      res = input('\nCopy and past your credentials from the login page:\n','s');

      % Convert string to struct with field names and values
      keyVals = strsplit(res, '&');
      credentialsStruct = struct();
      for index = 1:size(keyVals,2)
          pair = strsplit(keyVals{index},'=');
          credentialsStruct.(string(pair(1))) = string(pair(2));
      end

      % expires_at should be double to compare to posixtime
      credentialsStruct.expires_at = str2double(credentialsStruct.expires_at);

      r = credentialsStruct;
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
