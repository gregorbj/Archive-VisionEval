# VisionEval GUI
VisionEval R Shiny GUI and Scenario Viewer (Visualizer)

See [Getting Started](https://github.com/gregorbj/VisionEval/wiki/Getting-Started)

VisionEval GUI (VEGUI) is an application built in R that supports VisionEval. It provides a useful interface for running a limited selection of VisionEval based models. It also offers various features like changing the input parameters to the models and visualizing the results of the model run.

VEGUI is a [Shiny](https://www.rstudio.com/products/shiny/) based application. It runs on a local server (where the application is initiated). The structural components of VEGUI are shown below.

<!-- ![input](../www/vegui_inputs.png "input") -->

<!-- ![output](../www/vegui_outputs.png "output") -->

## Relation between input and output

| Input                             | Output                             |
| :----                             | :----                              |
|`SELECT_RUN_SCRIPT_BUTTON`	        | `COPY_MODEL_BUTTON`                |
|`RUN_MODEL_BUTTON`	                | `RUN_MODEL_BUTTON`                 |
|`SAVE_MODEL_PARAMETERS_FILE`	      | `SAVE_MODEL_PARAMETERS_FILE`       |
|`REVERT_MODEL_PARAMETERS_FILE`	    | `REVERT_MODEL_PARAMETERS_FILE`     |
|`SAVE_RUN_PARAMETERS_FILE`	        | `SAVE_RUN_PARAMETERS_FILE`         |
|`REVERT_RUN_PARAMETERS_FILE`	      | `REVERT_RUN_PARAMETERS_FILE`       |

## Reactive variables

| Variable                  | Sub-Variable                 | Data Type |
| :-------                  | :-----------                 | :-------- |
| `otherReactiveValues_rv`	| `DEBUG_CONSOLE_OUTPUT`	     | `data.table` |
| `otherReactiveValues_rv`	| `MODULE_PROGRESS`	           | `data.table` |
| `reactiveFilePaths_rv`	  | `CAPTURED_SOURCE`	           | `string` |
| `reactiveFilePaths_rv`	  | `parameterFileIdentifier`	   | `string` |
| `reactiveFilePaths_rv`    | `MODEL_STATE_FILE`           | `string` |
| `reactiveFilePaths_rv`    | `VE_LOG`                     | `string` |
| `reactiveFilePaths_rv`    | `DATASTORE`                  | `string` |
| `reactiveFilePaths_rv`    | `MODEL_PARAMETERS_FILE`      | `string` |
| `reactiveFilePaths_rv`    | `RUN_PARAMETERS_FILE`        | `string` |
| `reactiveFilePaths_rv`    | `GEO_CSV_FILE`               | `string` |
| `reactiveFilePaths_rv`    | `OUTPUT_DIR`                 | `string` |
| `reactiveFileReaders_ls`	| `VE_LOG`	                   | `array (string)` |
| `reactiveFileReaders_ls`	| `CAPTURED_SOURCE`	           | `array (string)` |
| `reactiveFileReaders_ls`	| `MODEL_PARAMETERS_FILE`	     | `data.frame` |
| `reactiveFileReaders_ls`	| `RUN_PARAMETERS_FILE`	       | `data.frame` |


## Output and trigger functions/variables

| Output                        | Trigger Function                      | Trigger Variable |
| :-----                        | :---------------                      | :--------------- |
|`SCRIPT_NAME`	                | `renderText`	                        | `getScriptInfo()$datapath` |
|`MODEL_MODULES`	              | `DT::renderDataTable`	                | `getScriptInfo()` |
|`MODEL_MODULES`	              | `DT::renderDataTable`	                | `getModelModules()` |
|`RUN_PARAMETERS_RHT`           | `rhandsontable::renderRHandsontable`  | `REVERT_RUN_PARAMETERS_FILE` |
|`RUN_PARAMETERS_RHT`           | `rhandsontable::renderRHandsontable`  | `reactiveFileReaders_ls[[RUN_PARAMETERS_FILE]]` |
|`MODEL_PARAMETERS_RHT`         | `rhandsontable::renderRHandsontable`  | `REVERT_MODEL_PARAMETERS_FILE`|
|`MODEL_PARAMETERS_RHT`         | `rhandsontable::renderRHandsontable`  | `reactiveFileReaders_ls[[MODEL_PARAMETERS_FILE]]`|
|`RUN_PARAMETERS_FILE`          | `renderText`                          | `reactiveFilePaths_rv[[RUN_PARAMETERS_FILE]]`|
|`MODEL_PARAMETERS_FILE`        | `renderText`                          | `reactiveFilePaths_rv[[MODEL_PARAMETERS_FILE]]`|
|`EDITOR_INPUT_FILE_IDENTIFIER`	| `renderText`	                        | `otherReactiveValues_rv[[EDITOR_INPUT_FILE_IDENTIFIER]]` |
|`EDITOR_INPUT_FILE_RHT`        | `rhandsontable::renderRHandsontable`	| `otherReactiveValues_rv[[EDITOR_INPUT_FILE_DT]]` |
|`MODULE_PROGRESS`	            | `DT::renderDataTable`	                | `getModuleProgress()` |
|`CAPTURED_SOURCE`	            | `renderText`	                        | `reactiveFileReaders_ls[[CAPTURED_SOURCE]]()` |
|`OUTPUT_FILE_PATH`             | `renderText`                          | `OUTPUT_FILE` |
|`OUTPUT_FILE_RHT`              | `rhandsontable::renderRHandsontable`  | `output_rht`  |
|`OUTPUT_FILE_SAVE_BUTTON`      | `downloadHandler`                     | `OUTPUT_FILE_RHT` |

## Observe

| Trigger Variable                                  | Expression | Comment |
| :---------------                                  | :--------- | :------ |
| `input[[SELECT_RUN_SCRIPT_BUTTON]]`	              | `observe({ shinyjs::toggleState(id = COPY_MODEL_BUTTON, condition = input[[SELECT_RUN_SCRIPT_BUTTON]], selector = NULL) })` | Activates copy button whenever input has a value |
| `input[[SELECT_RUN_SCRIPT_BUTTON]]`	              | `observe({ shinyjs::toggle(... condition = input[[SELECT_RUN_SCRIPT_BUTTON]], ... selector = "#navlist li a[data-value^=TAB_]" ) })` | Activates TAB related buttons whenever trigger variable has a value |
| `getInputFiles`                                   | `observe({if ( length(getInputFiles()) > 0 ){...})` | Updates selector of input files whenever getInputFiles changes values |
| `input[[INPUT_FILES]]`                            | `observe({fileName <- input[[INPUT_FILES]] ...})`   | Reads fileName into a data table for display |
| `otherReactiveValues_rv[[EDITOR_INPUT_FILE]]`	    | `observe({ shinyjs::toggle( id = NULL, condition = data.table::is.data.table(otherReactiveValues_rv[[EDITOR_INPUT_FILE]]), anim = TRUE, animType = "Slide", time = 0.25, selector = "#EDITOR_INPUT_FILE, #EDITOR_INPUT_FILE_IDENTIFIER" ) })`                | Activates editor button whenever the trigger variable has a value |
| `otherReactiveValues_rv[[EDITOR_INPUT_FILE_DT]]`  | `observe({dt <- otherReactiveValues_rv[[EDITOR_INPUT_FILE_DT]]; if (data.table::is.data.table(dt)){ shinyjs::show(id = EDITOR_INPUT_DIV) }})` | Shows the input file table if `dt` is a table |
|  	|` observe( label = "processRunningTasks", x = { invalidateLater(DEFAULT_POLL_INTERVAL) processRunningTasks(debug = TRUE) } )` | Invalidates after the default poll interval and call `processRunningTasks` |
| `getOutputFiles`                                  | `observe({if ( length(getOutputFiles()) > 0 ){...})` | Updates selector of output files whenever getOutputFiles changes values |


## Observe Event

| Label | Event Expression | Comment |
| :---- | :--------------- | :------ |
| `RUN_MODEL_BUTTON`	| `input[[RUN_MODEL_BUTTON]]` | Runs the selected model |
| `SAVE_MODEL_PARAMETERS_FILE`	| `input[[SAVE_MODEL_PARAMETERS_FILE]]` | Saves the model parameters to a file |
| `REVERT_MODEL_PARAMETERS_FILE`	| `input[[REVERT_MODEL_PARAMETERS_FILE]]` | Reverts the changes made to the model parameters |
| `SAVE_RUN_PARAMETERS_FILE`	| `input[[SAVE_RUN_PARAMETERS_FILE]]` | Save the run parameters to a file |
| `REVERT_RUN_PARAMETERS_FILE`	| `input[[REVERT_RUN_PARAMETERS_FILE]]` | Reverts the changes made to the model parameters |
| `INPUT_FILE_SAVE_BUTTON`      | `input[[INPUT_FILE_SAVE_BUTTON]]`  | Saves the input parameters to a file |
| `INPUT_FILE_REVERT_BUTTON`    | `input[[INPUT_FILE_REVERT_BUTTON]]` | Reverts changes made to input parameters |

## Reactive Event

| Label | Event Expression | Comment |
| :---- | :--------------- | :------ |
| `getScriptInfo`	| `input[[SELECT_RUN_SCRIPT_BUTTON]]` | Get the script related information and create a model environment |
| `output_rht`    | `input[[OUTPUT_FILE]]` | Create an rhandsontable to show output data |

