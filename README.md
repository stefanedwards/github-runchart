# github-runchart
Demonstration of Shiny for dashboard with a runchart.

Available online on shiny.io at

## Run yourself

If you want to run this demonstration yourself, it is necessary to **update the authentication values**.

1. Go to https://github.com/settings/developers

2. Register a new 'OAuth application'; the 'Callback URL' was set to http://localhost:1410 for this one.

3. Update app.R lines 28-30 (ish):
  
  
    myapp <- oauth_app(appname = "R/Shiny Github Runchart",
                   key = "fd2195405c8488f56680",
                   secret = "fe06be1b88b010fc95dbc226eed2082dad8ede9a")
  
  where `key` is the Client ID and `secret` is Client secret.
  
4. Run the app to generate a token file, `.httr-oauth`. Alternatively, run

```
library(httpuv)
library(httr)
    
# Can be github, linkedin etc depending on application
oauth_endpoints("github")
 
# Change based on what you   < REMEMBER TO UPDATE THESE LINES >
myapp <- oauth_app(appname = "R/Shiny Github Runchart",
                   key = "fd2195405c8488f56680",
                   secret = "fe06be1b88b010fc95dbc226eed2082dad8ede9a")

# Get OAuth credentials
github_token <- oauth2.0_token(oauth_endpoints("github"), myapp)
```

## Resources

Getting data from the Github API was followed from https://towardsdatascience.com/accessing-data-from-github-api-using-r-3633fb62cb08
