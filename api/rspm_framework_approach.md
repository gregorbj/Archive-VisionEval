## NOTE THIS DOCUMENTS IS PROVIDED FOR VISIONEVAL BACKGROUND, IT IS NOT A CURRENT SPECIFICATION OF THE VISIONEVAL MODEL SYSTEM 

## VisionEval: A New Framework for the GreenSTEP Family of Models: Overview and Approach

**Brian Gregor, Oregon Systems Analytics LLC**  
**Tara Weidner, Oregon Department of Transportation**  
**10/9/15**

This white paper outlines the vision, approach, and timeline for developing a new framework for the GreenSTEP family of models, VisionEval. It is intended to provide an understanding of key objectives and end products, as well as the path to get there.

### Project Purpose and Vision
ODOT developed the GreenSTEP model for statewide use, and a rebranded metropolitan version of the model as the Regional Strategic Planning Model (RSPM). The GreenSTEP/RSPM models have proven to be successful in providing modeling support for several high profile state and metropolitan area planning applications. These **successes** include:

- Development of a legislatively mandated statewide strategy for reducing greenhouse gas emissions from the transportation sector;
  
- Development of the legislatively mandated analysis of the potential for reducing greenhouse gas emissions from light-duty vehicles in metropolitan areas;

- Development of scenario plans for metropolitan areas; and

- Analysis of the potential effects of advanced vehicles on gas tax revenues.   

In addition, the GreenSTEP model has been adapted for use by other states in the form of the Federal Highway Administration’s (FHWA) Emissions Reduction Policy Analysis Tool (EERPAT), and portions of the model became the underlying basis of the SHRP2 C16 Rapid Policy Assessment Tool (RPAT, formerly SmartGAP).  

The GreenSTEP/RSPM models are disaggregate strategic planning models, and have introduced a number of innovative concepts to transportation modeling, winning a national award from the American Association of State Highway Transportation Officials (AASHTO) in 2010. The term “disaggregate strategic planning model” represents several distinguishing features of these models. They are disaggregate in the sense that they model aspects (i.e. characteristics and behaviors) of individual households. They are strategic planning models because they are used to support long-range strategic planning processes such as visioning, policy development, and scenario planning where many alternatives and potential conditions need to be modeled to address a range of possibilities and uncertainties. In strategic planning models, some detail is sacrificed to enable a much larger number of alternatives and aspects to be modeled.

The success of the tool has resulted in four slightly different models, sufficiently different so that model upgrades are not easily shared. The goal of this effort is to put the models in a common modularized framework. In addition to increasing collaboration, the new framework addresses several limitations that have become apparent through the use of these models. Some of these **limitations** include:  

- The structure of data storage and retrieval scales poorly with large populations and large numbers of household attributes. This shows up in the need for large computer memories when modeling large populations and in increasing time performance penalties as more household attributes are added.

- The models are not modular enough to enable new capabilities to be added in a plug-and-play fashion. This makes the code more difficult to extend and maintain than it needs to be, and limits the ability of other developers to contribute to improving the models.

- The structure of the data storage also increases the difficulty of producing performance measures from model outputs. The models produces a wealth of information for calculating performance measures, but a substantial amount of scripting is required in order to retrieve that information and calculate measures.

This project will create a new model framework for implementing disaggregate strategic planning models including the GreenSTEP/RSPM models. The **design goals** for the new model framework will be:

1. Modular: A model will specify in a simple declarative script the model modules to be used. Modules will be packaged in standard R language packages.

2. Open: Clear standards and guidelines will enable developers anywhere to create modules and/or combine modules into new or improved models.

3. Scalable: Models will be able to be built for regions of varying population sizes, from small town to large metropolitan area or state.

4. Accessible: Data will be managed in a persistent store to mediate between modules and enable performance measures to be produced using simple commands.

5. Quick: Short runtimes are key to allowing a large number of model runs to strategically assess a wide variety of synergistic policy actions under future uncertainties.

6. Simple UI: A well structured user interface to facilitate a limited set of inputs and flexible outut processing  is essential. A Graphical User Interface may help, depending upon the user community.

### General Approach to Development
Even though the GreenSTEP/RSPM models are innovative, they were developed on tight timelines and with a strong customer orientation. This was made possible by following agile modeling practices and by developing and implementing the models in the [R  language](http://www.r-project.org) and environment for statistical computing and graphics. These **agile modeling practices** will be incorporated into the development of the new framework including:

- Lightweight design up front.

- Iterative development, by doing just enough to meet needs and then revising and refactoring as needed.

- Modular development with testing throughout the development of each module.

- Paying attention to customer needs, understanding what information works in their policy forums, and anticipating their needs.

The R language played a key role by enabling a continuous development process from data exploration, to model estimation, to model implementation, to model testing, to model integration, and finally to model application.

The development of the new framework will follow these successful **practices**.

- The organizing concepts for the framework are based on extensive use of the GreenSTEP/RSPM models and customer requests.

- Development will proceed iteratively from a light-weight design. Components will be developed and tested in iterations to create core functionality and then to extend the functionality as needed.

- At periodic intervals the components will be integrated and tested together.

- Revisions to the individual components will be made as necessary to assure successful integration.

- Documentation and development of specifications will proceed in tandem.

- Organizational requirements will be kept as simple as possible for prospective module developers.

### Framework Overview
The new framework is named *VisionEval*. This framework will enable many types of strategic planning models to be assembled for regions of many different sizes, from small metropolitan areas to multi-state regions. The GreenSTEP model will be one type of model built within the VisionEval framework. An overview of the envisioned framework is presented here to provide a context for understanding the work scope. Figure 1 illustrates the primary elements of the framework.

**Figure 1. Overview of VisionEval Framework**

![Framework Diagram](img/framework_diagram.png)

A model operating in the framework is composed of **two groups of
components**.

- **Model Components** (shown in orange) - These includes components created by module developers and assemblers. These components are not strictly part of the framework, rather they are created in compliance with framework standards. The standards assure that module components can use the framework services and can be assembled into working models. There are two types of model components, packages and model scripts.

	- **Packages** – These are compilations of one or more model modules. A model module contains all of the information needed to implement a model which calculates some attribute (e.g. household income). The information components of a module are shown in Figure 1. Any number of modules can be included in a package. The package includes documentation for the included modules, R scripts and data that were used for estimating the modules, examples for using the modules, and test data.

	- **Model Scripts** - A model script creates a model by calling on the services of a number of model modules. A model script is a simple text file which calls on framework services to initialize a model and then specifies a sequence of calls to modules, by module name and package name.

-   **Framework Services** (shown in blue) - These include all of the services provided by the framework. These run in the background and require no attention by module developers and assemblers.

	-   **Data Store** - This is a file which contains all the data that is used by and created by a model. The data is organized into groups of attributes such as household attributes, vehicle attributes, and place attributes. The file will be addressable so that the data written to or read from the file is only what is needed. The data store will also contain the metadata including units for all data elements. The HDF5 file format will be used for the datastore.

    -   **Framework Functions** - The heart of the framework is a set of functions which provide essential services for creating and managing the data store, checking models to make sure that all the needed data is available or will be created in the proper order for the model to run correctly, reading and writing to the data store, running modules, and calculating performance measures from the data store.

    -   **Run Script** - Describes the basic services that the framework provides when it executes a module.

Three types of users are anticipated to use this framework:

-   **Module developers** create model modules that are distributed in standard R packages. For example, Figure 1 illustrates 3 packages named “HH”, “Auto”, and “Travel”. A package may contain several modules. The figure shows 3 modules in the HH package: SynthesizeHH, PredictWkr, and PredictInc. Each module contains all of the information needed for it to be executed in the framework. This is illustrated in the “Module Components” box.

-   **Model assemblers** create a model by writing an R script which specifies the order in which modules will be executed. The script may execute modules in a sequential manner or may include more complicated looping constructs.

-   **Model users** prepare inputs for an assembled model, run the model, and extract model outputs typically to support planning decisions or research objectives.

### Development Approach
The development of the framework and conversion of existing models to the new framework will occur in two phases. In the first phase the framework functionality, specifications, application programming interface and prototype modules will be developed. A second phase will complete the conversion of ODOT [(GreenSTEP and RSPM)](http://www.oregon.gov/ODOT/TD/OSTI/Pages/scenario_planning.aspx#reg) and FHWA ([EERPAT](https://planning.dot.gov/FHWA_tool/) and [RPAT](https://planningtools.transportation.org/10/23/183/10/travelworks.html)) models into the new framework.

**Phase I** of the new framework conversion effort will create and test all of the framework specifications and services. It will also demonstrate the specifications by creating several prototype modules that are bundled as R packages. In addition, common procedures used in the various model functions will be identified and generalized framework functions for
carrying out these procedures will be developed in order to reduce code redundancy and to facilitate the development of new modules. This task will also unify how the state and metropolitan versions of the models treat geographic units. Although the state model imputes many geographic characteristics and the metropolitan RSPM treats them explicitly, the same data store structure will be used for both. Finally this task will show how simple model run scripts are written to assemble modules into running models. Phase I tasks include:  

1.	**Project kickoff and review of overview and approach** - Convene a technical review group of model developers, academics, technical users, and agency sponsors. Review and finalize the framework approach. 

2.   **Set-up development work environment** - Set up collaborative open source development work environment, shared repository on GitHub, scripting standards, model estimation package documentation/standards, package development environment, and initial documentation for creating module packages.

3.   **Develop Data Store and Functionality for Interaction** - Develop specifications for the design of a data store using [HDF5 file format](http://www.hdfgroup.org/HDF5/). This file format is used by the new [open matrix standard for travel models](https://github.com/osPlanning/omx). In addition, [R language support for HDF5 is available](http://www.bioconductor.org/packages/release/bioc/html/rhdf5.html). Subtasks include developing specifications for the data store, interaction tests, interaction functions, prototypes, and documentation. This task will proceed in tandem with the fourth task (develop module structure). The work on both tasks will proceed in iterations where each successive iteration increases functionality and detail. Each iteration will involve improving specifications, documentation, code, and testing. 

4.   **Develop Module Structure and Functions to Run a Module** - Define what is required of a module to work within the common framework, including supporting structure and functions.  In general, a model module must contain all of the information needed by the framework functions to retrieve needed inputs from the data store, execute the module, and save the results to the data store.  In addition, given this information the framework must perform validation of a model script, checking whether all of the inputs needed by each module are available when needed by the module. Subtasks include developing module specifications, describing functionality within modules and for interacting with modules, developing module tests, developing two prototype modules, and developing framework functions for interacting with modules. Work on this task will proceed in tandem with work on the third task.
 
5.   **Develop Specifications, Procedures, and Tools for Developing Packages for Model Modules** - Specifications, procedures and tools will be developed to guide users in the development of model modules. Subtasks include developing specifications for model packages and tests for package sufficiency, developing a model package template and functions for testing package sufficiency, developing and testing a prototype package using the prototype modules developed in the fourth task, and writing instructions for developing packages.

6.   **Final Documentation** - Final documentation will be developed which describes the final framework, provides instructions for model assemblers and developers, reports prototype results, lessons learned and time expended, provides recommendations on converting existing strategic planning models to the framework, describes outstanding issues, and offers implementation cautions.

Phase I is intended to be accomplished over approximately 5 - 6 month period. The timing of tasks and important milestones is shown in the following figure. 

**Figure 2. Phase I Development Timeline**

![Framework Diagram](img/framework_timeline.png)

**Phase II** is anticipated to involve the conversion of the latest versions of ODOT's GreenSTEP and RSPM models to the VisionEval framework. The new framework-based versions will be tested with inputs that are the same as existing model runs to assure that they produce the same outputs as those model runs. Key tasks will be to convert the latest version of GreenSTEP and the metropolitan RSPM, and to package the new models into a set of R packages. Conversion of the Federal EERPAT tool is intended to be implemented in a separate phase. The full benefits of this common framework are realized when all four tools are converted. A timeline and workscope for Phase II will be developed at a later date.
