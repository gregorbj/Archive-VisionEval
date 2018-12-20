var catconfig = [
  {
    "NAME": ["Community Design"],
    "DESCRIPTION": ["Local policies to enable shorter trips and travel by alternate modes."],
    "LEVELS": [
      {
        "NAME": ["1"],
        "INPUTS": [
          {
            "NAME": ["L"],
            "LEVEL": ["1"]
          },
          {
            "NAME": ["B"],
            "LEVEL": ["1"]
          },
          {
            "NAME": ["T"],
            "LEVEL": ["1"]
          },
          {
            "NAME": ["P"],
            "LEVEL": ["1"]
          }
        ]
      },
      {
        "NAME": ["2"],
        "INPUTS": [
          {
            "NAME": ["L"],
            "LEVEL": ["2"]
          },
          {
            "NAME": ["B"],
            "LEVEL": ["1"]
          },
          {
            "NAME": ["T"],
            "LEVEL": ["2"]
          },
          {
            "NAME": ["P"],
            "LEVEL": ["1"]
          }
        ]
      },
      {
        "NAME": ["3"],
        "INPUTS": [
          {
            "NAME": ["L"],
            "LEVEL": ["2"]
          },
          {
            "NAME": ["B"],
            "LEVEL": ["1"]
          },
          {
            "NAME": ["T"],
            "LEVEL": ["3"]
          },
          {
            "NAME": ["P"],
            "LEVEL": ["2"]
          }
        ]
      },
      {
        "NAME": ["4"],
        "INPUTS": [
          {
            "NAME": ["L"],
            "LEVEL": ["2"]
          },
          {
            "NAME": ["B"],
            "LEVEL": ["2"]
          },
          {
            "NAME": ["T"],
            "LEVEL": ["3"]
          },
          {
            "NAME": ["P"],
            "LEVEL": ["2"]
          }
        ]
      }
    ]
  },
  {
    "NAME": ["Marketing/Incentive"],
    "DESCRIPTION": ["Local programs to improve driving efficiency & reduce auto demand."],
    "LEVELS": [
      {
        "NAME": ["1"],
        "INPUTS": [
          {
            "NAME": ["D"],
            "LEVEL": ["1"]
          },
          {
            "NAME": ["E"],
            "LEVEL": ["1"]
          }
        ]
      },
      {
        "NAME": ["2"],
        "INPUTS": [
          {
            "NAME": ["D"],
            "LEVEL": ["2"]
          },
          {
            "NAME": ["E"],
            "LEVEL": ["2"]
          }
        ]
      }
    ]
  },
  {
    "NAME": ["Pricing"],
    "DESCRIPTION": ["State-led policies that move towards true cost pricing."],
    "LEVELS": [
      {
        "NAME": ["1"],
        "INPUTS": [
          {
            "NAME": ["C"],
            "LEVEL": ["1"]
          }
        ]
      },
      {
        "NAME": ["2"],
        "INPUTS": [
          {
            "NAME": ["C"],
            "LEVEL": ["2"]
          }
        ]
      },
      {
        "NAME": ["3"],
        "INPUTS": [
          {
            "NAME": ["C"],
            "LEVEL": ["3"]
          }
        ]
      }
    ]
  },
  {
    "NAME": ["Vehicles/Fuels"],
    "DESCRIPTION": ["Factors representing changes to future vehicles and fuels."],
    "LEVELS": [
      {
        "NAME": ["0"],
        "INPUTS": [
          {
            "NAME": ["V"],
            "LEVEL": ["1"]
          },
          {
            "NAME": ["F"],
            "LEVEL": ["1"]
          }
        ]
      },
      {
        "NAME": ["1"],
        "INPUTS": [
          {
            "NAME": ["V"],
            "LEVEL": ["2"]
          },
          {
            "NAME": ["F"],
            "LEVEL": ["1"]
          }
        ]
      },
      {
        "NAME": ["2"],
        "INPUTS": [
          {
            "NAME": ["V"],
            "LEVEL": ["2"]
          },
          {
            "NAME": ["F"],
            "LEVEL": ["2"]
          }
        ]
      }
    ]
  },
  {
    "NAME": ["Fuel Price"],
    "DESCRIPTION": ["Context factor on the assumed market price of gasoline (exclusive of fuel taxes.)"],
    "LEVELS": [
      {
        "NAME": ["0"],
        "INPUTS": [
          {
            "NAME": ["G"],
            "LEVEL": ["1"]
          }
        ]
      },
      {
        "NAME": ["1"],
        "INPUTS": [
          {
            "NAME": ["G"],
            "LEVEL": ["2"]
          }
        ]
      },
      {
        "NAME": ["2"],
        "INPUTS": [
          {
            "NAME": ["G"],
            "LEVEL": ["3"]
          }
        ]
      }
    ]
  },
  {
    "NAME": ["Income"],
    "DESCRIPTION": ["Context factor on the assumed growth of statewide average per capita income."],
    "LEVELS": [
      {
        "NAME": ["0"],
        "INPUTS": [
          {
            "NAME": ["I"],
            "LEVEL": ["1"]
          }
        ]
      },
      {
        "NAME": ["1"],
        "INPUTS": [
          {
            "NAME": ["I"],
            "LEVEL": ["2"]
          }
        ]
      },
      {
        "NAME": ["2"],
        "INPUTS": [
          {
            "NAME": ["I"],
            "LEVEL": ["3"]
          }
        ]
      }
    ]
  }
];
