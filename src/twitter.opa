// license: AGPL
// (c) MLstate, 2011, 2012
// author: Adam Koprowski

import stdlib.apis.{twitter, oauth}

database Twitter.configuration /twitter_config

type Twitter.credentials = {no_credentials}
                        or {string request_secret, string request_token}
                        or {Twitter.credentials authenticated}

module TwitterConnect
{

  server config =
    _ = CommandLine.filter(
      { init: void
      , parsers: [{ CommandLine.default_parser with
          names: ["--twitter-config"],
          param_doc: "APP_KEY,APP_SECRET",
          description: "Sets the application data for the associated Twitter application",
          function on_param(state) {
            parser {
              case app_key=Rule.alphanum_string [,] app_secret=Rule.alphanum_string:
              {
                  /twitter_config <- { consumer_key: app_key,
                                       consumer_secret: app_secret
                                     }
                {no_params: state}
              }
            }
          }
        }]
      , anonymous: []
      , title: "Twitter configuration"
      }
    )
    match (?/twitter_config) {
      case {some: config}: config
      default:
        Log.error("webshell[config]", "Cannot read Twitter configuration (application key and/or secret key)
Please re-run your application with: --twitter-config option")
        System.exit(1)
    }

  private TW = Twitter(config)
  private TWA = OAuth(TW.oauth_params({fast}))

  private redirect = "http://{Config.host}/connect/twitter"

  function login(raw_token) {
    error("YYY")
  }

  private function authenticate() {
    match (TWA.get_request_token(redirect)) {
    case {~error}:
      Service.respond_with(<>Twitter authorization failed</>)
    case {success: token}:
      auth_url = TWA.build_authorize_url(token.token)
      auth_state = {request_secret: token.secret, request_token: token.token}
      { response: {redirect: auth_url},
        state_change: {new_state: auth_state}
      }
    }
  }

  private function tweet(state, content) {
    match (state) {
    case {authenticated: creds}:
      Service.respond_with(<>Unimplemented...</>)
    default:
      authenticate()
    }
  }

  Service.spec spec =
    { initial_state: Twitter.credentials {no_credentials},
      metadata: {
        id: "twitter",
        description: "Managing Twitter account",
        cmds: [
          { cmd: "tweet [content]", description: "Publishes a given tween" }
        ],
      },
      function parse_cmd(state) {
        parser {
        case "tweet" Rule.ws content=(.*) : tweet(state, Text.to_string(content))
        }
      }
    }

}
