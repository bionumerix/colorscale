
#' Color Scale Shiny Gadget
#'
#' Interactively create a color palette from a unique color
#'
#' @param color Hexadecimal string or a name for color.
#' @param viewer Where to display the gadget: \code{"dialog"},
#'  \code{"pane"} or \code{"browser"} (see \code{\link[shiny]{viewer}}).
#'
#' @export
#'
#' @importFrom miniUI miniPage miniContentPanel
#' @importFrom htmltools tags
#' @importFrom shiny uiOutput renderUI runGadget paneViewer actionButton browserViewer
#'  sliderInput splitLayout icon dialogViewer stopApp observeEvent reactiveValues
#'  showModal modalDialog actionLink req
#' @importFrom shinyWidgets spectrumInput chooseSliderSkin prettyRadioButtons prettyToggle
#' @importFrom glue double_quote glue
#' @importFrom stringi stri_c
#' @importFrom rstudioapi getSourceEditorContext insertText
#'
#' @examples
#' \dontrun{
#'
#' if (interactive()) {
#'
#' # Launch the gadget with :
#' one_color_scale()
#'
#' }
#'
#' }
one_color_scale <- function(color = "#1D9A6C", viewer = getOption(x = "colorscale.viewer", default = "pane")) {
  stopifnot(length(color) == 1)

  ui <- miniPage(
    chooseSliderSkin("Modern", color = "#112446"),
    # style sheet
    tags$link(rel="stylesheet", type="text/css", href="colorscale/styles.css"),
    # title
    tags$div(
      class="gadget-title dreamrs-title-box",
      tags$h1(icon("paint-brush"), "Color Scale from one color", class = "dreamrs-title"),
      actionButton(
        inputId = "close", label = "Close",
        class = "btn-sm pull-left",
        icon = icon("times")
      ),
      actionButton(
        inputId = "launch_modal_code",
        label = "Code",
        class = "btn-sm pull-right",
        icon = icon("code")
      )
    ),
    # body
    miniContentPanel(
      padding = 10,
      splitLayout(
        tags$div(
          tags$b("Input color:"),
          spectrumInput(
            inputId = "main_col",
            label = NULL,
            selected = color, width = "90%",
            options = list(
              "show-buttons" = FALSE,
              "preferred-format" = "hex",
              "show-input" = TRUE
            )
          )
        ),
        tags$div(
          style = "height: 70px;",
          tags$div(style = "height: 25px;"),
          prettyToggle(
            inputId = "play_color",
            value = TRUE,
            label_on = "Play",
            label_off = "Pause",
            outline = TRUE,
            plain = TRUE,
            bigger = TRUE,
            inline = FALSE,
            icon_on = icon("play-circle-o", class = "fa-2x"),
            icon_off = icon("pause-circle-o", class = "fa-2x")
          )
        )
      ),
      # tags$br(),
      tags$b("Output palette:"),
      uiOutput(outputId = "rect_cols"),
      tags$br(),
      splitLayout(
        tags$div(
          sliderInput(
            inputId = "n_dark",
            label = "Number of dark colors:",
            min = 1,
            max = 10,
            value = 4,
            width = "90%"
          ),
          sliderInput(
            inputId = "p_dark",
            label = "Percentage of darkness:",
            min = 0,
            max = 100,
            value = 50,
            post = "%",
            width = "90%"
          ),
          sliderInput(
            inputId = "a_dark",
            label = "Dark hue angle:",
            min = -360,
            max = 360,
            value = -51,
            post = "\u00b0",
            width = "90%"
          ),
          sliderInput(
            inputId = "s_dark",
            label = "Dark colors saturation:",
            min = -100,
            max = 100,
            value = -14,
            post = "%",
            width = "90%"
          )
        ),
        tags$div(
          sliderInput(
            inputId = "n_light",
            label = "Number of light colors:",
            min = 1,
            max = 10,
            value = 6,
            width = "90%"
          ),
          sliderInput(
            inputId = "p_light",
            label = "Percentage of lightness:",
            min = 0,
            max = 100,
            value = 80,
            post = "%",
            width = "90%"
          ),
          sliderInput(
            inputId = "a_light",
            label = "Light hue angle:",
            min = -360,
            max = 360,
            value = 67,
            post = "\u00b0",
            width = "90%"
          ),
          sliderInput(
            inputId = "s_light",
            label = "Light colors saturation:",
            min = -100,
            max = 100,
            value = 20,
            post = "%",
            width = "90%"
          )
        )
      )
    )
  )

  server <- function(input, output, session) {

    result_scale <- reactiveValues(colors = NULL, code = "")

    output$rect_cols <- renderUI({
      req(input$play_color, cancelOutput = TRUE)
      color <- input$main_col
      res_colors <- single_scale(
        color = color,
        n_dark = input$n_dark,
        darkness = input$p_dark / 100,
        rotate_dark = input$a_dark,
        saturation_dark = input$s_dark / 100,
        n_light = input$n_light,
        lightness = input$p_light / 100,
        rotate_light = input$a_light,
        saturation_light = input$s_light / 100
      )
      result_scale$colors <- res_colors
      colors_rect(colors = res_colors)
    })

    observeEvent(input$launch_modal_code, {
      showModal(modalDialog(
        title = "Code",
        prettyRadioButtons(
          inputId = "raw_or_fun",
          label = NULL,
          choices = c("Raw vector", "Function call"),
          shape = "round", fill = TRUE, inline = TRUE
        ),
        uiOutput(outputId = "render_code"),
        actionLink(
          inputId = "insert_script",
          label = "Insert in current script",
          icon = icon("arrow-left ")
        )
      ))
    })

    output$render_code <- renderUI({
      req(input$raw_or_fun)
      if (input$raw_or_fun == "Raw vector") {
        code <- glue::glue(
          "c({colors})\n",
          colors = stri_c(glue::double_quote(result_scale$colors), collapse = ", ")
        )
      } else {
        code <- glue::glue(
          "single_scale(
          color = {color},
          n_dark = {n_dark},
          darkness = {darkness},
          rotate_dark = {rotate_dark},
          saturation_dark = {saturation_dark},
          n_light = {n_light},
          lightness = {lightness},
          rotate_light = {rotate_light},
          saturation_light = {saturation_light}
        )\n",
          color = glue::double_quote(color),
          n_dark = input$n_dark,
          darkness = input$p_dark / 100,
          rotate_dark = input$a_dark,
          saturation_dark = input$s_dark / 100,
          n_light = input$n_light,
          lightness = input$p_light / 100,
          rotate_light = input$a_light,
          saturation_light = input$s_light / 100
        )
      }
      result_scale$code <- code
      tags$code(tags$pre(code))
    })

    observeEvent(input$insert_script, {
      context <- rstudioapi::getSourceEditorContext()
      rstudioapi::insertText(text = result_scale$code, id = context$id)
    })

    observeEvent(input$close, stopApp())

  }

  if (viewer == "dialog") {
    viewer <- dialogViewer("C'est le temps que tu as perdu pour ta rose qui rend ta rose importante.")
  } else if (viewer == "browser") {
    viewer <- browserViewer()
  } else {
    viewer <- paneViewer(minHeight = 600)
  }
  runGadget(app = ui, server = server, viewer = viewer)
}




