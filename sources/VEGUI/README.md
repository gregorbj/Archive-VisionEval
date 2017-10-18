# VisionEval GUI
VisionEval R Shiny GUI and Scenario Viewer (Visualizer)

See [Getting Started](https://github.com/gregorbj/VisionEval/blob/master/README.md) to install and run.

VisionEval GUI (VEGUI) is an application built in R that supports VisionEval. It provides a useful interface for running a limited selection of VisionEval based models. It also offers various features like changing the input parameters to the models and visualizing the results of the model run.

VEGUI is a [Shiny](https://www.rstudio.com/products/shiny/) based application. It runs on a local server (where the application is initiated). The structural components of VEGUI is shown below.

<!-- ![input](../www/vegui_inputs.png "input") -->

<!-- ![output](../www/vegui_outputs.png "output") -->

## Relation between input and output

| Input | Output |
| :---- | :---- |
|`SELECT_RUN_SCRIPT_BUTTON`	| `COPY_MODEL_BUTTON` |
|`RUN_MODEL_BUTTON`	| `RUN_MODEL_BUTTON` |
|`SAVE_MODEL_PARAMETERS_FILE`	| `SAVE_MODEL_PARAMETERS_FILE` |
|`REVERT_MODEL_PARAMETERS_FILE`	| `REVERT_MODEL_PARAMETERS_FILE` |
|`SAVE_RUN_PARAMETERS_FILE`	| `SAVE_RUN_PARAMETERS_FILE` |
|`REVERT_RUN_PARAMETERS_FILE`	| `REVERT_RUN_PARAMETERS_FILE` |
|`DATASTORE_TABLE_CLOSE_BUTTON`	| `DATASTORE_TABLE_CLOSE_BUTTON` |
|`DATASTORE_TABLE_EXPORT_BUTTON`	| `DATASTORE_TABLE_EXPORT_BUTTON` |
|`EDIT_INPUT_FILE_LAST_CLICK`	| `EDIT_INPUT_FILE_LAST_CLICK` |
|`DATASTORE_TABLE_row_last_clicked`	| `DATASTORE_TABLE_row_last_clicked` |

## Reactive variables

| Variable | Sub-Variable | Data Type |
| :------- | :----------- | :-------- |
| `otherReactiveValues_rv`	| `DEBUG_CONSOLE_OUTPUT`	| `data.table` |
| `otherReactiveValues_rv`	| `MODULE_PROGRESS`	| `data.table` |
| `reactiveFilePaths_rv`	| `CAPTURED_SOURCE`	| `string` |
| `reactiveFilePaths_rv`	| `parameterFileIdentifier`	| `string` |
| `reactiveFileReaders_ls`	| `VE_LOG`	| `array (string)` |
| `reactiveFileReaders_ls`	| `DATASTORE`	| `data.table` |
| `reactiveFileReaders_ls`	| `CAPTURED_SOURCE`	| `array (string)` |
| `reactiveFileReaders_ls`	| `MODEL_PARAMETERS_FILE`	| `data.frame` |
| `reactiveFileReaders_ls`	| `RUN_PARAMETERS_FILE`	| `data.frame` |
| `reactiveFileReaders_ls`	| `GEO_CSV_FILE`	| `data.frame` |
| `reactiveFileReaders_ls`	| `MODEL_STATE_FILE`	| `list` |


## Output and trigger functions/variables

| Output | Trigger Function | Trigger Variable |
| :----- | :--------------- | :--------------- |
|`EDITOR_INPUT_FILE_IDENTIFIER`	| `renderText`	| `otherReactiveValues_rv[[EDITOR_INPUT_FILE_IDENTIFIER]]` |
|`EDITOR_INPUT_FILE`	| `rhandsontable::renderRHandsontable`	| `otherReactiveValues_rv[[EDITOR_INPUT_FILE]]` |
|`SCRIPT_NAME`	| `renderText`	| `getScriptInfo()$datapath` |
|`DATASTORE_TABLE_IDENTIFIER`	| `renderText`	| `otherReactiveValues_rv[[DATASTORE_TABLE_IDENTIFIER]]` |
|`VIEW_DATASTORE_TABLE`	| `DT::renderDataTable`	| `otherReactiveValues_rv[[VIEW_DATASTORE_TABLE]]` |
|`DATASTORE_TABLE`	| `DT::renderDataTable`	| `reactiveFileReaders_ls[[DATASTORE]]()` |
|`GEO_CSV_FILE`	| `DT::renderDataTable`	| `reactiveFileReaders_ls[[GEO_CSV_FILE]]()` |
|`MODEL_STATE_FILE`	| `renderText`	| `getScriptInfo()` |
|`MODEL_STATE_FILE`	| `renderText`	| `reactiveFileReaders_ls[[MODEL_STATE_FILE]]()` |
|`MODULE_PROGRESS`	| `DT::renderDataTable`	| `getModuleProgress()` |
|`CAPTURED_SOURCE`	| `renderText`	| `reactiveFileReaders_ls[[CAPTURED_SOURCE]]()` |
|`MODEL_MODULES`	| `DT::renderDataTable`	| `getScriptInfo()` |
|`MODEL_MODULES`	| `DT::renderDataTable`	| `getModelModules()` |
|`INPUT_FILES`	| `DT::renderDataTable`	| `getOutputINPUT_FILES()` |
|`HDF5_TABLES`	| `DT::renderDataTable`	| `getOutputHDF5_TABLES()` |
|`INPUTS_TREE_SELECTED_TEXT`	| `renderText`	| `getOutputINPUTS_TREE_SELECTED_TEXT()` |
|`INPUTS_TREE`	| `renderTree`	| `getInputsTree()` |
|`VE_LOG`	| `DT::renderDataTable`	| `getScriptInfo()` |
|`VE_LOG`	| `DT::renderDataTable`	| `reactiveFileReaders_ls[[VE_LOG]]()` |
|`DEBUG_CONSOLE_OUTPUT`	| `DT::renderDataTable`	| `otherReactiveValues_rv[[DEBUG_CONSOLE_OUTPUT]]` |

## Observe

| Trigger Variable | Expression | Comment |
| :--------------- | :--------- | :------ |
| `input[[SELECT_RUN_SCRIPT_BUTTON]]`	| `observe({ shinyjs::toggleState(id = COPY_MODEL_BUTTON, condition = input[[SELECT_RUN_SCRIPT_BUTTON]], selector = NULL) })` | Activates copy button whenever input has a value |
| `otherReactiveValues_rv[[EDITOR_INPUT_FILE]]`	| `observe({ shinyjs::toggle( id = NULL, condition = data.table::is.data.table(otherReactiveValues_rv[[EDITOR_INPUT_FILE]]), anim = TRUE, animType = "Slide", time = 0.25, selector = "#EDITOR_INPUT_FILE, #EDITOR_INPUT_FILE_IDENTIFIER" ) })` | Activates editor button whenever the trigger variable has a value |
| `otherReactiveValues_rv[[VIEW_DATASTORE_TABLE]]`	| `observe({ shinyjs::toggle( id = NULL, condition = data.table::is.data.table(otherReactiveValues_rv[[VIEW_DATASTORE_TABLE]]), anim = TRUE, animType = "Slide", time = 0.25, selector = "#VIEW_DATASTORE_TABLE, #DATASTORE_TABLE_EXPORT_BUTTON, #DATASTORE_TABLE_IDENTIFIER, #DATASTORE_TABLE_CLOSE_BUTTON" ) })` | Activates datastore related buttons/tables whenever trigger variable has a value |
| `input[[SELECT_RUN_SCRIPT_BUTTON]]`	| `observe({ shinyjs::toggle( id = NULL, condition = input[[SELECT_RUN_SCRIPT_BUTTON]], anim = TRUE, animType = "Slide", time = 0.25, selector = "#navlist li a[data-value^=TAB_]" ) })` | Activates TAB related buttons whenever trigger variable has a value |
|  	|` observe( label = "processRunningTasks", x = { invalidateLater(DEFAULT_POLL_INTERVAL) processRunningTasks(debug = TRUE) } )` | Invalidates after the default poll interval and call `processRunningTasks` |
| `reactiveFileReaders_ls[[MODEL_PARAMETERS_FILE]]()`	| `observe({ shinyAce::updateAceEditor( session, MODEL_PARAMETERS_FILE, value = jsonlite::toJSON(reactiveFileReaders_ls[[MODEL_PARAMETERS_FILE]](), pretty = TRUE) ) shinyAce::updateAceEditor( session, RUN_PARAMETERS_FILE, value = jsonlite::toJSON(reactiveFileReaders_ls[[RUN_PARAMETERS_FILE]](), pretty = TRUE) ) })` | Updates the run and model parameters when triggered |
| `reactiveFileReaders_ls[[RUN_PARAMETERS_FILE]]()`	| `observe({ shinyAce::updateAceEditor( session, MODEL_PARAMETERS_FILE, value = jsonlite::toJSON(reactiveFileReaders_ls[[MODEL_PARAMETERS_FILE]](), pretty = TRUE) ) shinyAce::updateAceEditor( session, RUN_PARAMETERS_FILE, value = jsonlite::toJSON(reactiveFileReaders_ls[[RUN_PARAMETERS_FILE]](), pretty = TRUE) ) })` | Updates the run and model parameters when triggered |


## Observe Event

| Label | Event Expression | Comment |
| :---- | :--------------- | :------ |
| `RUN_MODEL_BUTTON`	| `input[[RUN_MODEL_BUTTON]]` | Runs the selected model |
| `SAVE_MODEL_PARAMETERS_FILE`	| `input[[SAVE_MODEL_PARAMETERS_FILE]]` | Saves the model parameters to a file |
| `REVERT_MODEL_PARAMETERS_FILE`	| `input[[REVERT_MODEL_PARAMETERS_FILE]]` | Reverts the changes made to the model parameters |
| `SAVE_RUN_PARAMETERS_FILE`	| `input[[SAVE_RUN_PARAMETERS_FILE]]` | Save the run parameters to a file |
| `REVERT_RUN_PARAMETERS_FILE`	| `input[[REVERT_RUN_PARAMETERS_FILE]]` | Reverts the changes made to the model parameters |
| `DATASTORE_TABLE_CLOSE_BUTTON`	| `input[[DATASTORE_TABLE_CLOSE_BUTTON]]` | Hides a data table |
| `DATASTORE_TABLE_EXPORT_BUTTON`	| `input[[DATASTORE_TABLE_EXPORT_BUTTON]]` | Export a data table to a file |
| `EDIT_INPUT_FILE_LAST_CLICK`	| `input[[EDIT_INPUT_FILE_LAST_CLICK]]` | Allows editing and saving of input files when clicked on it |
| `DATASTORE_TABLE_row_last_clicked`	| `input$DATASTORE_TABLE_row_last_clicked` | Reads hdf5 table into variables |

## Reactive Event

| Label | Event Expression | Comment |
| :---- | :--------------- | :------ |
| `getScriptInfo`	| `input[[SELECT_RUN_SCRIPT_BUTTON]]` | Get the script related information and create a model environment |
