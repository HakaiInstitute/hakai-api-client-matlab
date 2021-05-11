# Hakai Api Matlab Client

# Requirements

# Installation

Copy The Hakai package folder into your matlab path with or place in the working directory of your project.
```matlab
% Add package +Hakai to your script
addpath('[path-to-directory]/hakai-api-client-matlab');
```

# Quickstart

```matlab
% Get the api request client
client = Hakai.Client();

% Make a data request for sampling stations
url = sprintf('%s/%s',client.api_root,'eims/views/output/chlorophyll?limit=20');
response = client.get(url);

disp(url); % https://hecate.hakai.org/api/eims/views/output/chlorophyll...
disp(response); % response will be a matlab 20x1 struct
disp(struct2table(response)); % convert struct to a table for easy viewing
```

## Methods

This library exports the `Hakai` package with a single class named `Client`. Instantiating this class sets up the credentials for requests using the `get` method.

The hakai_api `Client` class also contains a property `api_root` which is useful for constructing urls to access data from the API. The above [Quickstart example](#quickstart) demonstrates using this property to construct a url to access chlorophyll data.

If for some reason your credentials become corrupted and stop working, there is a method to remove the old cached credentials for your account so you can re-authenticate. Simply call the method like so `client.remove_old_credentials()`.

## API endpoints

For details about the API, including available endpoints where data can be requested, see the [Hakai API documentation](https://github.com/HakaiInstitute/hakai-api).

## Advanced usage

You can specify which API to access when instantiating the Client. By default, the API uses `https://hecate.hakai.org/api` as the API root. It may be useful to use this library to access a locally running API instance or to access the Goose API for testing purposes.

Goose and Hecate use the same tokens, so you can either instantiate the client using Goose as the API root, or use Goose when making the requests.

```matlab
% Get a client for Goose and make requests as usual
client = Hakai.Client('https://goose.hakai.org/api')
disp(client.api_root) % https://goose.hakai.org/api
url = sprintf('%s/%s',client.api_root,'eims/views/output/chlorophyll?limit=20');
response = client.get(url);

% Use Hecate client to access Goose
client = Hakai.Client();
disp(client.api_root) % https://hecate.hakai.org/api
url = sprintf('%s/%s','https://goose.hakai.org/api','eims/views/output/chlorophyll?limit=20');
response = client.get(url);
```

You won't be able to create a localhost token, but you can instantiate a Goose or Hecate client and then use it to query a locally running API instance that has local auth disabled.

```matlab
% Use Hecate client to query locally running API instance
client = Hakai.Client();
url = sprintf('%s/%s','http://localhost:8666','eims/views/output/chlorophyll?limit=20');
```

### Author

Matthew Foster(matthew.foster@hakai.org)

Copyright (c) 2017 Hakai Institute and individual contributors All Rights Reserved.
