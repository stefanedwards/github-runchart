#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(jsonlite)
#install.packages("httpuv")
library(httpuv)
#install.packages("httr")
library(httr)
library(dplyr)
library(ggplot2)
library(lubridate)
library(lemon)
library(purrr)
options(stringsAsFactors = FALSE)

# setup -----
# Can be github, linkedin etc depending on application
oauth_endpoints("github")

# Change based on what you 
myapp <- oauth_app(appname = "R/Shiny Github Runchart",
                   key = "fd2195405c8488f56680",
                   secret = "fe06be1b88b010fc95dbc226eed2082dad8ede9a")

# Get OAuth credentials
github_token <- oauth2.0_token(oauth_endpoints("github"), myapp)
gtoken <- config(token = github_token)

rf2 <- function(x) x[c('id','type','created_at')] %>% as.data.frame
rf <- function(x, y) bind_rows(rf2(x), rf2(y))


update_events <- function(start=NULL) {
  if (!is.null(start) && is.POSIXct(start))
    start <- as.integer(seconds(start))
  
  events <- data.frame()
  for (i in 1:30) {
    req <- GET("https://api.github.com/events", gtoken, page=i)
    stop_for_status(req)
    df <- content(req) %>% reduce(.f=rf) %>%
      mutate(created_at=ymd_hms(created_at), ts=as.integer(seconds(created_at)))
    if (is.null(start))
      start <- max(df$ts) - 4
    events <- bind_rows(df, events)
    if (min(events$ts) <= start)
      break
  }
  filter(events, between(ts, start+1, max(ts) - 1))
}



# Define UI for application that draws a histogram
ui <- fluidPage(
   
   # Application title
   titlePanel("Github public events"),
   p('This Shiny app displays public events from the ', 
      a('Github API', href='https://developer.github.com/v3/activity/events/#list-public-events'),
     '.', br(),
     'Please wait 5-10 seconds while data is being fetched.', br(),
     'Plot area greys out as the data is being fetched from the Github API; 
     ideally it would be set up in an asynchronous manner.'),
   
  # Show a plot of the generated distribution
  mainPanel(
    textOutput('nah'),
     plotOutput("bigplot")
  )
)

# Define server logic required to draw a histogram
server <- function(input, output, session) {
   
  events <- update_events() %>% count(type, created_at) %>%
    filter(type %in% c('PushEvent','CreateEvent','PullRequestEvent'))
  
  data <- reactivePoll(5000, session,
    checkFunc = Sys.time,
    valueFunc = function() {
      events <<- update_events(max(events$created_at)) %>% 
        count(type, created_at) %>%
        filter(type %in% c('PushEvent','CreateEvent','PullRequestEvent')) %>%
        bind_rows(events) %>%
        filter(created_at > max(created_at) - 120)
      return(events)
    }
  )
  
  output$bigplot <- renderPlot({
    df <- data()
    diff <- seconds(max(df$created_at) - min(df$created_at))
    start <- min(df$created_at)
    if (as.integer(diff) < 120) {
      end <- start + 120
    } else {
      end <- max(df$created_at)
    }
    df %>% ggplot(aes(x=created_at, y=n, colour=type, group=type)) + 
      geom_line() + geom_point() +
      coord_capped_cart(xlim=c(start, end), bottom='none', left='none') +
      scale_x_datetime('Time', timezone='CEST', date_labels='%H:%M:%S') +
      facet_rep_wrap(~type, ncol=1, scales='free_y') +
      labs(y='Events per second')
  })
}

# Run the application 
shinyApp(ui = ui, server = server)

