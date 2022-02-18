#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(markovtext)
library(promises)
library(future)
library(bslib)
library(shinycssloaders)

#library(bs4Dash)

# Define UI for application that draws a histogram
ui <- fluidPage(
    theme = bslib::bs_theme(bootswatch = "flatly"),

    tags$head(tags$style(type="text/css",
                         HTML('.container-fluid {  max-width: 1000px; padding:25px; margin-left: auto; margin-right: auto; }'))),

    # Application title
    titlePanel("Random Text with Markov Chains!"),

    # Sidebar with a slider input for number of bins
    tabsetPanel(
        tabPanel("Introduction",
                 h3("Welcome!"),
                 p("This is a deeply unserious demo app that lets you generate random text that's probabilistically modeled on a specific input text."),
                 h4("Okay, how do I use it?"),
                 p("Two tabs contain the main functions:"),
                 tags$ul(
                     tags$li(tags$em("Pre-Supplied Texts"), " lets you generate text based on well-known sources, including Dr. Seuss and Doug Ford."),
                     tags$li(tags$em("User-Supplied Texts"), " lets you enter your own text to mimic."),
                 ),
                 h4("Sounds cool, how does it work?"),
                 p("Nothing fancy, just high-school level math."),
                 tags$ul(tags$li("First, take some input text and find the unique words and the order they tend to come in."),
                         tags$li("To generate text, choose the next word based on what tends to come after the last one or two words.")
                 ),

                 h4("What's the point?"),
                 p("Entertainment, mostly."),
                 p("But in an era of ever-escalating computation-hungry language models, I was also curious about whether
                  you could generate semi-plausible natural language using a dumb-as-rocks lo-fi approach. Honestly, you
                  could recreate this method with nothing but a pencil, paper, calculator, and set of D&D dice."),
                 # tags$ul(tags$li("First, take some input text and find the unique words and the order they tend to come in."),
                 #         tags$li("To generate text, choose the next word based on what tends to come after the last one or two words.")
                 # ),
                 h4("Can I learn more?"),
                 p("Sure, click the ", tags$em("More Info"), " tab to learn more about me and this project.")
                 #
                 #               tags$li("First we take an input text and look at it word-by-word, seeing which words
                 # tend to follow which. This gives us a big list of words and relative frequencies.
                 #                  (For simplicity, we count punctuation marks as words.)"),
                 #                tags$li("To generate text, the next word is chosen based on the one
                 #                  or two last words, using the big table of frequencies we prepared earlier."),
                 #                p("Different texts put different words in different ways, so
                 #                  the outputs have the same 'flavour' as the inputs.")
                 #               )
        ),
        tabPanel("Pre-Supplied Texts",
                 sidebarLayout(
                     sidebarPanel( width = 4,

                                   title = "Text Parameters",
                                   shiny::selectInput("wordfreqs",
                                                      label = "Choose a Text to Simulate:",
                                                      choices = c("The Whale's Monologue", "Cat in the Hat", "One Fish Two Fish", "Doug Ford (2-grams)", "Doug Ford (3-grams)", "Nietzsche"),
                                                      selected = "Doug Ford (3-grams)"
                                   ),
                                   shiny::sliderInput("numwords", "# Words to Generate:", value = 100, min=10, max=250),
                                   shiny::actionButton("generate_button",
                                                       "Generate Text")
                     ),
                     mainPanel(
                         # Show a plot of the generated distribution
                         textOutput("generated_text") %>%
                             shinycssloaders::withSpinner()
                     )
                 )
        ),

        tabPanel("User-Supplied Texts",
                 sidebarLayout(
                     sidebarPanel( width = 4,

                                   shiny::textAreaInput("usertext",
                                                        label = "Text to Replicate: (5000 chars max)",
                                                        value = "Text goes here. This is where text goes! Enter text that you like. I like to enter text. Do you like to enter text? You do like text! I hope you like text as much as I like text."
                                   ),
                                   shiny::selectInput("user_words",
                                                      "# Distinct Words to Include:",
                                                      choices = c(100, 250, 500),
                                                      selected = 500),
                                   shiny::selectInput("user_ngrams",
                                                      "N-grams to process:",
                                                      choices = c("2-grams" = 2, "3-grams" = 3),
                                                      selected = "3-grams"),
                                   shiny::sliderInput("numwords_user", "# Words to Generate:", value = 100, min=10, max=250),
                                   shiny::actionButton("generate_button_user",
                                                       "Generate Text")
                     ),
                     mainPanel(
                         # Show a plot of the generated distribution
                         textOutput("generated_text_user") %>%
                             shinycssloaders::withSpinner()
                     )
                 )
        ),

        tabPanel("More Info",
                 h3("About this app"),
                 p("This web app is written in R using Shiny. It's mostly base Shiny with minor
  custom CSS and some theming from the bslib package. The algorithm is written
  using tidyverse functions, almost exclusively dplyr."),
                 tags$ul(
                     tags$li("The app code is available on Github ", tags$a("here", href = "https://github.com/chris31415926535/shiny_markov_text"), "."),
                     tags$li("The algorithm is available as an R package on Github ", tags$a("here", href = "https://github.com/chris31415926535/markovtext"), ".")
                 ),
                 h3("About me"),
                 p("I'm a data scientist and researcher. My main interests at
                 the moment are building interactive data analysis and visualization
                 apps using Shiny, natural language processing with a focus on
                 social media, geospatial analysis with a focus on access to
                 healthcare, and qualitative research methods with a focus on
                 phenomenological analysis."),
                 p(tags$a("Visit my personal website here", href = "https://cbelanger.netlify.app"),
                   "and", tags$a("my professional website here", href = "https://www.belangeranalytics.com"), "."),
                 h3("About the algorithm"),
                 p("Text is generated using probabilistic model based on Markov chains."),
                 h4("Processing input text"),
                 p("An input text is first broken down into ordered
  word tokens, with the punctuation marks ',', '.', '!', and '?' treated as special words. We then count the tokens and
  select only the top n (500 in this case). We next go through the text in order and count the number of times each word
  appears after each sequence of 1 or 2 words. Finally, we group by initial strings of 1 or 2 words and compute the
  relative frequencies of each final word, which we will use as probabilities for generating text."),
                 h4("Generating output text"),
                 p("Once you have your word-frequency table, generating text is straightforward:
  look at the last 1 or 2 words, find the next possible words and their probabilities based on the relative
  frequencies, and choose one randomly.")

        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output) {

    #future::plan(future::multisession())

    generated_text <- NULL
    wordfreqs <- NULL


    text <- shiny::eventReactive(input$generate_button, {

        message("button clicked")

        numwords <- input$numwords
        if (input$wordfreqs == "The Whale's Monologue") wordfreqs <- markovtext::wordfreqs_whale_3grams
        if (input$wordfreqs == "Cat in the Hat") wordfreqs <- markovtext::wordfreqs_catinthehat_3grams
        if (input$wordfreqs == "Doug Ford (2-grams)") wordfreqs <- markovtext::wordfreqs_dougford_2grams
        if (input$wordfreqs == "Doug Ford (3-grams)") wordfreqs <-  markovtext::wordfreqs_dougford_3grams
        if (input$wordfreqs == "One Fish Two Fish") wordfreqs <- markovtext::wordfreqs_onefishtwofish_3grams
        if (input$wordfreqs == "Whale's Monologue") wordfreqs <- markovtext::wordfreqs_whale_3grams
        if (input$wordfreqs == "Nietzsche") wordfreqs <- markovtext::wordfreqs_zarathustra_3grams


        # note: app crashes on my AWS tiny Shiny server when I use future_promise
        # possibly because it only has one core to begin with? unclear.
        #future_promise( {markovtext::generate_text(wordfreqs, word_length = numwords)} , seed = as.numeric(Sys.time()))

        markovtext::generate_text(wordfreqs, word_length = numwords)
    })

    output$generated_text <- renderText(
        text() %>% paste0("...") #%...>% paste0("...")
    )


    text_user <- shiny::eventReactive(input$generate_button_user, {

        message("button clicked for user-supplied text")

        numwords <- input$numwords_user
        input_text <- dplyr::tibble(text = substr(input$usertext, 1, 5000))
        ngrams <- input$user_ngrams
        words_to_extract <- input$user_words

message(input$usertext)

        message("generating user-defined text")
        # see above: fails on my tiny AWS server when using future_promise
        # future_promise( {} , seed = as.numeric(Sys.time()))
        w <- markovtext::get_word_freqs(input_text, num_words =  words_to_extract, n_grams = ngrams)

        message(head(w))

        result <- try(markovtext::generate_text(w, word_length = numwords))

        if ("try-error" %in% class(result)){
          result <- "Please enter more text with that uses more than 3 or 4 different words."
        }

        result
    })

    output$generated_text_user <- renderText(
        text_user() %>% paste0("...")# %...>% paste0("...")
    )
}

# Run the application
shinyApp(ui = ui, server = server) #%>%  bslib::run_with_themer()
