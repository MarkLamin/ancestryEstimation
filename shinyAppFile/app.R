#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#

#machine learning
library(randomForest)
library(uwot)

#packages for data wrangling
library(data.table)
library(magrittr)
library(tidyverse)

#libraries for web apps
library(shiny)
library(DT)

#visual aesthetics
library(RColorBrewer)

popLabels <- fread("PopLabels.txt", header = F) |>
  set_colnames(c("SampleID", "Region"))

pcTable <- fread("../pcaResult.eigenvec") |>
  select(-V1) |>
  set_colnames(c("SampleID", paste0("PC", 1:20))) |>
  left_join(y = popLabels, by = "SampleID") |>
  mutate(trainingPopLabel = if_else(
    condition = is.na(Region),
    true = "Study Sample",
    false = Region
  ))

PC_RF_Train <- pcTable |>
  filter(is.na(Region) |> not()) |>
  column_to_rownames("SampleID")

PC_RF_Test <- pcTable |>
  filter(is.na(Region)) |>
  column_to_rownames("SampleID")

UMAP_Table <- fread("../bigUmapResults.csv")[, 2:3] |>
  mutate(SampleID = pcTable$SampleID) |>
  left_join(y = popLabels, by = "SampleID") |>
  mutate(trainingLabel = if_else(
    condition = is.na(Region),
    true = "Study Sample",
    false = Region
  ))

#title is long, so I put it as a separate thing
eigValPlotTitle <-
  "Contribution of Successive Principal Components to Variance Explained"

#this part of plot does not depend on user input
eigValPlot <- fread("../pcaResult.eigenval") %>%
  mutate(numComponent = 1:nrow(.)) %>%
  ggplot(mapping = aes(x = numComponent, y = V1)) +
  geom_point(color = "darkblue") +
  geom_line(color = "darkblue") +
  theme_bw()  +
  labs(
    x = "Principal Components",
    y = "Variance",
    title = eigValPlotTitle,
    subtitle = "(User-Specified Threshold in Red)"
  )

# Define UI for application
ui <- fluidPage(
  # Application title
  titlePanel("Ancestry Estimation"),
  tabsetPanel(
    #Tab 1: PCA ----
    tabPanel(
      title = "PCA",
      # Sidebar with a slider input for number of PCs
      sidebarLayout(
        sidebarPanel = sidebarPanel(
          sliderInput(
            inputId = "numComponent",
            label = "How many PCs?",
            min = 1,
            max = 20,
            value = 8
          ),
          checkboxGroupInput(
            inputId = "popOptions",
            label = "Regions",
            choices = pcTable$trainingPopLabel |> unique(),
            selected = pcTable$trainingPopLabel |> unique()
          ),
          selectInput(
            inputId = "xAxisPC",
            label = "X-Axis PC",
            choices = paste0("PC", 1:(ncol(pcTable) - 3)),
            selected = "PC1"
          ),
          selectInput(
            inputId = "yAxisPC",
            label = "Y-Axis PC",
            choices = paste0("PC", 1:(ncol(pcTable) - 3)),
            selected = "PC2"
          )
        ),
        
        # Show a plot of variance explained
        mainPanel = mainPanel(plotOutput("varianceExplained"), plotOutput("pcPlot"))
      )
    ),
    
    #Tab 2: PC + RF ----
    tabPanel(
      title = "PC + Random Forest",
      sidebarLayout(
        sidebarPanel = sidebarPanel(
          sliderInput(
            inputId = "numComponentPC_RF",
            label = "How many PCs?",
            min = 1,
            max = ncol(pcTable) - 3,
            value = 8
          ),
          h3("Random Forest Settings"),
          sliderInput(
            inputId = "PC_RF_ntree",
            label = "How many trees?",
            min = 100L,
            max = 1000L,
            value = 500L
          ),
          uiOutput("PC_RF_mtry"),
          sliderInput(
            inputId = "PC_RF_nodesize",
            label = "Minimum Nodesize?",
            min = 1L,
            max = 10L,
            step = 1L,
            value = 1L
          ),
          h3("Evaluation Metrics"),
          div(
            strong("OOB Error on Reference Panel:"),
            # This acts as a label
            textOutput("PC_RF_TrainingError")
          ),
          h3("Prediction Classification"),
          sliderInput(
            inputId = "PC_RF_Threshold",
            label = "Confidence Threshold for Prediction Classification",
            min = 0,
            max = 1,
            value = 0.9
          ),
          h3("RFMix Results"),
          uiOutput("PC_RF_RFMix_Region"),
          selectInput(
            inputId = "PC_RF_RFMixSort",
            label = "Sort by",
            choices = fread("RFMixResults.csv") |> with(Region) |> unique()
          )
        ),
        mainPanel = mainPanel(
          plotOutput("PC_RF_Assignments"),
          plotOutput("PC_RF_Assignments_With_PC"),
          plotOutput("PC_RF_RFMixPlot")
        )
      )
    ),
    # Tab 3: UMAP ----
    tabPanel(
      title = "UMAP",
      sidebarLayout(
        sidebarPanel = sidebarPanel(
          checkboxGroupInput(
            inputId = "UMAP_Regions",
            label = "Regions",
            choices = UMAP_Table$trainingLabel |> unique(),
            selected = UMAP_Table$trainingLabel |> unique()
          )
        ),
        mainPanel = mainPanel(plotOutput("UMAP_Plot"))
      )
    ),
    #Tab 4: UMAP + RF ----
    tabPanel(title = "UMAP + Random Forest"),
    #Tab 5: PCA + UMAP ----
    tabPanel(
      title = "PCA + UMAP",
      titlePanel("UMAP on First 20 Principal Components"),
      sidebarLayout(
        sidebarPanel = sidebarPanel(
          checkboxGroupInput(
            inputId = "PC_UMAP_Regions",
            label = "Regions",
            choices = pcTable |> with(trainingPopLabel) |> unique(),
            selected = pcTable |> with(trainingPopLabel) |> unique()
          ),
          sliderInput(
            inputId = "PC_UMAP_KNN",
            "Neighborhood Size",
            min = 5,
            max = 50,
            value = 15,
            step = 1
          ),
          selectInput(
            inputId = "PC_UMAP_Metric",
            label = "Metric",
            choices = c("euclidean", "cosine", "manhattan", "hamming"),
            selected = "euclidean"
          )
        ),
        mainPanel = mainPanel(plotOutput("PC_UMAP_Plot"))
      )
    ),
    #Tab 6: PCA + UMAP + RF ----
    tabPanel(
      title = "PC + UMAP + Random Forest",
      sidebarLayout(
        sidebarPanel = sidebarPanel(
          h3("UMAP Settings"),
          sliderInput(
            inputId = "PC_UMAP_RF_N_Components",
            label = "How many components?",
            min = 2,
            max = 10,
            value = 5,
            step = 1
          ),
          sliderInput(
            inputId = "PC_UMAP_RF_KNN",
            label = "Neighborhood Size",
            min = 5,
            max = 50,
            value = 15,
            step = 1
          ),
          selectInput(
            inputId = "PC_UMAP_RF_Metric",
            label = "Metric",
            choices = c("euclidean", "cosine", "manhattan", "hamming"),
            selected = "euclidean"
          ),
          h3("Random Forest Settings"),
          sliderInput(
            inputId = "PC_UMAP_RF_ntree",
            label = "How many trees?",
            min = 100,
            max = 1000,
            value = 500,
            step = 1
          ),
          sliderInput(
            inputId = "PC_UMAP_RF_mtry",
            label = "Variables to select at each split?",
            min = 1,
            max = 10,
            value = 2,
            step = 1
          ),
          sliderInput(
            inputId = "PC_UAMP_RF_nodesize",
            label = "Minimum Nodesize?",
            min = 1,
            max = 10,
            value = 1,
            step = 1
          ),
          h3("Evaluation Metrics"),
          h5("OOB Error on Reference Panel"),
          textOutput("PC_UMAP_RF_Training_Error"),
          h3("Prediction Classification"),
          sliderInput(
            inputId = "PC_UMAP_RF_Threshold",
            label = "Confidence Threshold",
            min = 0,
            max = 1,
            value = 0.9
          ),
          h3("Comparison to RFMix"),
          uiOutput("PC_UMAP_RF_RFMixRegion"),
          selectInput(
            inputId = "PC_UMAP_RF_RFMixSort",
            label = "Sort by:",
            choices = fread("RFMixResults.csv") |> with(Region) |> unique()
          )
        ),
        mainPanel = mainPanel(
          plotOutput("PC_UMAP_RF_Prediction_Plot"),
          plotOutput("PC_UMAP_RF_RFMixPlot")
        )
      )
    ),
    # Tab 7: PC + RF vs. PC + UMAP + RF ----
    tabPanel(title = "Method Comparison",
             sidebarLayout(
               sidebarPanel = sidebarPanel(
                 uiOutput("PC_RF_RegionSelect"),
                 uiOutput("PC_UMAP_RF_RegionSelect")
               ),
               mainPanel = mainPanel(
                 DTOutput("PC_RF_VS_PC_UMAP_RF"),
                 verbatimTextOutput("PC_RF_VS_PC_UMAP_RF_CrossTable"),
                 plotOutput("RFMixComparison")
               )
             ))
    #end of UI ----
  )
)

# Define server logic
server <- function(input, output) {
  #Tab 1: PCA -----
  output$varianceExplained <- renderPlot({
    eigValPlot +
      geom_vline(
        xintercept = input$numComponent,
        color = "red",
        linetype = "dashed"
      )
  })
  
  output$pcPlot <-
    renderPlot({
      ggplot(
        data = pcTable |> filter(trainingPopLabel %in% input$popOptions),
        mapping = aes(
          x = !!sym(input$xAxisPC),
          y = !!sym(input$yAxisPC),
          color = Region
        )
      ) +
        geom_point(size = 3) +
        theme_bw() +
        labs(title = "Principal Component Analysis on Reference Panel and Study Sample") +
        scale_color_brewer(palette = "Dark2", na.value = "grey40") +
        theme(legend.text = element_text(size = 14),
              legend.title = element_text(size = 14))
    })
  
  #Tab 2: PC + RF -----
  output$PC_RF_mtry <-
    renderUI({
      sliderInput(
        inputId = "PC_RF_mtrySlider",
        label = "Variables to select at each split?",
        min = 1,
        max = input$numComponentPC_RF,
        value = max(floor(sqrt(
          input$numComponentPC_RF
        )), 1),
        step = 1
      )
    })
  
  PC_RF_Train_N_PC <- reactive({
    PC_RF_Train |>
      select(Region, all_of(paste0("PC", 1:input$numComponentPC_RF)))
  })
  
  PC_RF_Test_N_PC <- reactive({
    PC_RF_Test |>
      select(all_of(paste0("PC", 1:(
        input$numComponentPC_RF
      ))))
  })
  
  PC_RF_Object <-
    reactive({
      randomForest(
        formula = factor(Region) ~ .,
        data = PC_RF_Train_N_PC(),
        ntree = input$PC_RF_ntree,
        mtry = input$PC_RF_mtrySlider,
        nodesize = input$PC_RF_nodesize
      )
    })
  
  PC_RF_Predictions <-
    reactive({
      predict(object = PC_RF_Object(),
              newdata = PC_RF_Test_N_PC(),
              type = "prob") |>
        as.data.frame() |>
        rownames_to_column("SampleID") |>
        pivot_longer(cols = -SampleID,
                     names_to = "Region",
                     values_to = "Probability") |>
        slice_max(order_by = Probability,
                  by = SampleID,
                  with_ties = FALSE) |>
        mutate(
          confidentRegion =
            if_else(
              condition = Probability >= input$PC_RF_Threshold,
              true = Region,
              false = "Other"
            )
        ) |>
        left_join(y = pcTable, by = "SampleID")
    })
  
  output$PC_RF_Assignments <-
    renderPlot({
      ggplot(
        data = PC_RF_Predictions(),
        mapping = aes(x = confidentRegion,
                      color = confidentRegion,
                      fill = confidentRegion)
      ) +
        geom_bar() +
        theme_bw() +
        labs(
          x = "Region",
          title = "Predicted Regions on Study Sample Data",
          color = "Region",
          fill = "Region",
          subtitle = paste0("Confidence Threshold of ", input$PC_RF_Threshold)
        ) +
        scale_color_brewer(palette = "Dark2", na.value = "grey40") +
        scale_fill_brewer(palette = "Dark2", na.value = "grey40") +
        theme(legend.text = element_text(size = 14),
              legend.title = element_text(size = 14))
    })
  
  output$PC_RF_Assignments_With_PC <-
    renderPlot({
      ggplot(data = PC_RF_Predictions(),
             mapping = aes(x = PC1, y = PC2, color = confidentRegion)) +
        geom_point(size = 3) +
        theme_bw() +
        labs(
          title = "Study Sample Data with Principal Components and Predicted Regions",
          color = "Region",
          subtitle = paste0("Confidence Threshold of ", input$PC_RF_Threshold)
        ) +
        scale_color_brewer(palette = "Dark2", na.value = "grey40") +
        theme(legend.text = element_text(size = 14),
              legend.title = element_text(size = 14))
    })
  
  output$PC_RF_TrainingError <-
    renderText({
      PC_RF_Object() |>
        with(err.rate) |>
        as.data.frame() |>
        select(OOB) |>
        slice(n()) |>
        as.numeric()
    })
  
  output$PC_RF_RFMix_Region <- renderUI({
    selectInput(
      inputId = "PC_RF_RFMixSelectRegion",
      label = "Region for RFMix?",
      choices = PC_RF_Predictions() |> with(confidentRegion) |> unique(),
      selected = "Other"
    )
  })
  
  PC_RF_IDsForRFMix <-
    reactive({
      PC_RF_Predictions() |>
        filter(confidentRegion == input$PC_RF_RFMixSelectRegion) |>
        with(SampleID)
    })
  
  PC_RF_RFMixData <- reactive({
    fread("RFMixResults.csv") |>
      filter(SampleID %in% PC_RF_IDsForRFMix()) |>
      pivot_wider(id_cols = "SampleID",
                  names_from = "Region",
                  values_from = "Probability") |>
      mutate(SampleID = fct_reorder(factor(SampleID), .data[[input$PC_RF_RFMixSort]])) |>
      pivot_longer(cols = -SampleID,
                   names_to = "Region",
                   values_to = "Probability")
  })
  
  output$PC_RF_RFMixPlot <- renderPlot({
    ggplot(
      data = PC_RF_RFMixData(),
      mapping = aes(
        x = SampleID,
        y = Probability,
        color = Region,
        fill = Region
      )
    ) +
      geom_bar(stat = "identity") +
      theme_bw() +
      theme(axis.text.x = element_text(
        angle = 90,
        vjust = 0.5,
        hjust = 1
      )) +
      labs(
        x = "Sample",
        y = "Ancestral Decomposition",
        title = paste0(
          "Local Ancestry Estimation of Samples Predicted as ",
          input$PC_RF_RFMixSelectRegion
        )
      ) +
      scale_color_brewer(palette = "Dark2", na.value = "grey40") +
      scale_fill_brewer(palette = "Dark2", na.value = "grey40") +
      theme(
        legend.text = element_text(size = 14),
        legend.title = element_text(size = 14)
      )
  })
  
  #Tab 3: UMAP ----
  output$UMAP_Plot <-
    renderPlot({
      ggplot(
        data = UMAP_Table |> filter(trainingLabel %in% input$UMAP_Regions),
        mapping = aes(x = UMAP1, y = UMAP2, color = Region)
      ) +
        geom_point(size = 3) +
        theme_bw() +
        labs(x = "UMAP1", y = "UMAP2", title = "UMAP on Reference Panel and Study Sample Genotypes") +
        scale_color_brewer(palette = "Dark2", na.value = "grey40") +
        theme(legend.text = element_text(size = 14),
              legend.title = element_text(size = 14))
    })
  #Tab 4: UMAP + RF ----
  #Tab 5: UMAP + PCA ----
  
  PC_UMAP_Table <-
    reactive({
      pcTable |>
        column_to_rownames("SampleID") |>
        select(-Region,-trainingPopLabel) |>
        scale() |>
        umap(
          n_threads = 4,
          n_neighbors = input$PC_UMAP_KNN,
          metric = input$PC_UMAP_Metric
        ) |>
        as.data.frame() |>
        rownames_to_column("SampleID") |>
        set_colnames(c("SampleID", "UMAP1", "UMAP2")) |>
        left_join(y = popLabels, by = "SampleID") |>
        #select(-Population) |>
        mutate(trainingPopLabel = if_else(
          condition = is.na(Region),
          true = "Study Sample",
          false = Region
        ))
      
    })
  
  output$PC_UMAP_Plot <-
    renderPlot({
      ggplot(
        data = PC_UMAP_Table() |>
          filter(trainingPopLabel %in% input$PC_UMAP_Regions),
        mapping = aes(x = UMAP1, y = UMAP2, color = Region)
      ) +
        geom_point(size = 3) +
        theme_bw() +
        labs(title = "UMAP Coordinates on Principal Components of Reference Panel + Study Sample") +
        scale_color_brewer(palette = "Dark2", na.value = "grey40") +
        theme(legend.text = element_text(size = 14),
              legend.title = element_text(size = 14))
    })
  
  #Tab 6: PC + UMAP + RF ----
  PC_UMAP_RF_Prep <- reactive({
    pcTable |>
      column_to_rownames("SampleID") |>
      select(-Region, -trainingPopLabel) |>
      scale() |>
      umap(
        n_threads = 4,
        n_neighbors = input$PC_UMAP_RF_KNN,
        n_components = input$PC_UMAP_RF_N_Components,
        metric = input$PC_UMAP_RF_Metric
      ) |>
      as.data.frame() |>
      set_colnames(paste0("UMAP", 1:input$PC_UMAP_RF_N_Components)) |>
      rownames_to_column("SampleID") |>
      left_join(y = popLabels, by = "SampleID") |>
      #select(-Population) |>
      column_to_rownames("SampleID")
  })
  
  PC_UMAP_RF_Train <-
    reactive({
      PC_UMAP_RF_Prep() |> filter(is.na(Region) |> not())
    })
  
  PC_UMAP_RF_Test <-
    reactive({
      PC_UMAP_RF_Prep() |> filter(is.na(Region)) |> select(-Region)
    })
  
  PC_UMAP_RF_Object <-
    reactive({
      randomForest(
        formula = factor(Region) ~ .,
        data = PC_UMAP_RF_Train(),
        ntree = input$PC_UMAP_RF_ntree,
        mtry = min(input$PC_UMAP_RF_mtry, input$PC_UMAP_RF_N_Components),
        nodesize = input$PC_UAMP_RF_nodesize
      )
    })
  
  output$PC_UMAP_RF_Training_Error <-
    renderText({
      PC_UMAP_RF_Object() |>
        with(err.rate) |>
        as.data.frame() |>
        select(OOB) |>
        slice(n()) |>
        as.numeric()
    })
  
  PC_UMAP_RF_Predictions <-
    reactive({
      predict(object = PC_UMAP_RF_Object(),
              newdata = PC_UMAP_RF_Test(),
              type = "prob") |>
        as.data.frame() |>
        rownames_to_column("SampleID") |>
        pivot_longer(cols = -SampleID,
                     names_to = "Region",
                     values_to = "Probability") |>
        slice_max(order_by = Probability,
                  by = SampleID,
                  with_ties = FALSE) |>
        mutate(
          predictedClass = if_else(
            condition = Probability >= input$PC_UMAP_RF_Threshold,
            true = Region,
            false = "Other"
          )
        )
    })
  
  output$PC_UMAP_RF_Prediction_Plot <-
    renderPlot({
      ggplot(
        data = PC_UMAP_RF_Predictions(),
        mapping = aes(
          x = predictedClass,
          color = predictedClass,
          fill = predictedClass
        )
      ) +
        geom_bar() +
        theme_bw() +
        labs(
          x = "Region",
          color = "Region",
          fill = "Region",
          title = "Predicted Regions on Study Sample Data",
          subtitle = paste0("Confidence Threshold of ", input$PC_UMAP_RF_Threshold)
        ) +
        scale_color_brewer(palette = "Dark2", na.value = "grey40") +
        scale_fill_brewer(palette = "Dark2", na.value = "grey40") +
        theme(legend.text = element_text(size = 14),
              legend.title = element_text(size = 14))
    })
  
  output$prepTable <- renderDT(PC_UMAP_RF_Predictions())
  
  output$PC_UMAP_RF_RFMixRegion <-
    renderUI({
      selectInput(
        inputId = "PC_UMAP_RF_RFMixRegionSelect",
        label = "Region to Compare to RFMix?",
        choices = PC_UMAP_RF_Predictions() |>
          with(predictedClass) |>
          unique(),
        selected = "Other"
      )
    })
  
  PC_UMAP_RF_IDsForRFMix <-
    reactive({
      PC_UMAP_RF_Predictions() |>
        filter(predictedClass == input$PC_UMAP_RF_RFMixRegionSelect) |>
        with(SampleID)
    })
  
  PF_UMAP_RF_RFMixData <- reactive({
    fread("RFMixResults.csv") |>
      filter(SampleID %in% PC_UMAP_RF_IDsForRFMix()) |>
      pivot_wider(id_cols = "SampleID",
                  names_from = "Region",
                  values_from = "Probability") |>
      mutate(SampleID = fct_reorder(factor(SampleID), .data[[input$PC_UMAP_RF_RFMixSort]])) |>
      pivot_longer(cols = -SampleID,
                   names_to = "Region",
                   values_to = "Probability")
  })
  
  output$PC_UMAP_RF_RFMixPlot <-
    renderPlot({
      ggplot(
        data = PF_UMAP_RF_RFMixData(),
        mapping = aes(
          x = SampleID,
          y = Probability,
          color = Region,
          fill = Region
        )
      ) +
        geom_bar(stat = "identity") +
        theme_bw() +
        labs(
          title = paste0(
            "Local Ancestry Estimation of Samples Predicted as ",
            input$PC_UMAP_RF_RFMixRegionSelect
          )
        ) +
        scale_color_brewer(palette = "Dark2", na.value = "grey40") +
        scale_fill_brewer(palette = "Dark2", na.value = "grey40") +
        theme(
          legend.text = element_text(size = 14),
          legend.title = element_text(size = 14),
          axis.text.x = element_text(
            angle = 90,
            vjust = 0.5,
            hjust = 1
          )
        )
    })
  #Tab 7: PC + RF vs. PC + UMAP + RF ----
  #PC_UMAP_RF_Predictions
  
  PC_VS_PC_UMAP_comparisonDF <- reactive({
    inner_join(
      x = PC_RF_Predictions() |>
        select(SampleID, "PC_RandomForestPrediction" = confidentRegion),
      y = PC_UMAP_RF_Predictions() |>
        select(SampleID, "PC_UMAP_RandomForestPrediction" = predictedClass),
      by = "SampleID"
    ) 
  })
  
  output$PC_RF_VS_PC_UMAP_RF <- renderDT({
    PC_VS_PC_UMAP_comparisonDF()
  })
  
  output$PC_RF_VS_PC_UMAP_RF_CrossTable <-
    renderPrint({
      table(
        PC_RF = PC_VS_PC_UMAP_comparisonDF() |> with(PC_RandomForestPrediction),
        PC_RF_UMAP = PC_VS_PC_UMAP_comparisonDF() |> with(PC_UMAP_RandomForestPrediction)
      ) |> 
        ftable()
    })
  
  output$PC_RF_RegionSelect <-
    renderUI({
      selectInput(
        inputId = "PC_RF_RegionSelectInput",
        label = "Region from PC + Random Forest",
        choices = PC_VS_PC_UMAP_comparisonDF() |>
          with(PC_RandomForestPrediction) |>
          unique()
      )
    })
  
  output$PC_UMAP_RF_RegionSelect <-
    renderUI({
      selectInput(
        inputId = "PC_UMAP_RF_RegionSelectInput",
        label = "Region from PC + UMAP + Random Forest",
        choices = PC_VS_PC_UMAP_comparisonDF() |>
          with(PC_UMAP_RandomForestPrediction) |>
          unique()
      )
    })
  
  idsOfBothRegions <- reactive({
    PC_VS_PC_UMAP_comparisonDF() |>
      filter(
        PC_RandomForestPrediction == input$PC_RF_RegionSelectInput,
        PC_UMAP_RandomForestPrediction == input$PC_UMAP_RF_RegionSelectInput
      ) |> 
      with(SampleID)
  })
  
  output$RFMixComparison <-
    renderPlot({
      fread("RFMixResults.csv") |> filter(SampleID %in% idsOfBothRegions()) |>
        ggplot(mapping = aes(
          x = SampleID,
          y = Probability,
          color = Region,
          fill = Region
        )) +
        geom_bar(stat = "identity") +
        scale_color_brewer(palette = "Dark2", na.value = "grey40") +
        scale_fill_brewer(palette = "Dark2", na.value = "grey40")  +
        labs(
          x = "Sample",
          y = "Ancestral Decomposition",
          title = "Local Ancestry Inference",
          subtitle = paste0(
            "Samples Predicted as ",
            input$PC_RF_RegionSelectInput,
            " under PC+RF and ",
            input$PC_UMAP_RF_RegionSelectInput,
            " under PC+UMAP+RF"
          )
        ) +
        theme_bw() +
        theme(
          legend.text = element_text(size = 14),
          legend.title = element_text(size = 14),
          axis.text.x = element_text(
            angle = 90,
            vjust = 0.5,
            hjust = 1
          )
        )
    })
}

# Run the application
shinyApp(ui = ui, server = server)
