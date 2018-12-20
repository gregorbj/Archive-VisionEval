var scenconfig = [
  {
    "NAME": ["B"],
    "LABEL": ["Bicycles"],
    "DESCRIPTION": ["Network improvements, incentives, and technologies that encourage bicycling and other light-weight vehicle travel."],
    "INSTRUCTIONS": ["The diversion of single-occupant vehicle travel to bicycles, electric bicycles and other light-weight vehicles."],
    "LEVELS": [
      {
        "NAME": ["1"],
        "LABEL": ["Base"],
        "DESCRIPTION": ["Current bicyling percentage of SOV tours less than 20 miles (9.75%)"]
      },
      {
        "NAME": ["2"],
        "LABEL": ["Double"],
        "DESCRIPTION": ["Increase diversion of SOV tours to 20%"]
      }
    ]
  },
  {
    "NAME": ["D"],
    "LABEL": ["Demand Management"],
    "DESCRIPTION": ["Programs to encourage less private vehicle travel."],
    "INSTRUCTIONS": ["Programs and incentives which encourage people to drive less including ridesharing, van pooling, telecommuting, and transit subsidies."],
    "LEVELS": [
      {
        "NAME": ["1"],
        "LABEL": ["Base"],
        "DESCRIPTION": ["Existing level"]
      },
      {
        "NAME": ["2"],
        "LABEL": ["Double participation"],
        "DESCRIPTION": ["Double participations rates in ridesharing, etc."]
      },
      {
        "NAME": ["3"],
        "LABEL": ["Double participation & transit subsidy"],
        "DESCRIPTION": ["Double participations rates in ridesharing, etc. and double transit subsidy."]
      }
    ]
  },
  {
    "NAME": ["L"],
    "LABEL": ["Land Use"],
    "DESCRIPTION": ["Distribution of population and employment by place type."],
    "INSTRUCTIONS": ["The form in which development occurs (density, regional assessibility, mixed use, etc.) represented by the distribution of population and employment by place type."],
    "LEVELS": [
      {
        "NAME": ["1"],
        "LABEL": ["Base"],
        "DESCRIPTION": ["Maintain current distribution."]
      },
      {
        "NAME": ["2"],
        "LABEL": ["Shift to urban core"],
        "DESCRIPTION": ["Shift half of the suburban population and employment growth to urban core and close in communities."]
      }
    ]
  },
  {
    "NAME": ["P"],
    "LABEL": ["Parking"],
    "DESCRIPTION": ["Extent of and charges for priced parking."],
    "INSTRUCTIONS": ["The extent of paid parking and its price."],
    "LEVELS": [
      {
        "NAME": ["1"],
        "LABEL": ["Base"],
        "DESCRIPTION": ["Current extent and daily fee."]
      },
      {
        "NAME": ["2"],
        "LABEL": ["Increase fees to 20%"],
        "DESCRIPTION": ["Increase extent to cover 20% of workers and 20% of other parking."]
      },
      {
        "NAME": ["3"],
        "LABEL": ["Increase fees to 20% and double parking cost"],
        "DESCRIPTION": ["Increase extent to cover 20% of workers and 20% of other parking plus double parking price."]
      }
    ]
  },
  {
    "NAME": ["T"],
    "LABEL": ["Transit"],
    "DESCRIPTION": ["Level of public transit service."],
    "INSTRUCTIONS": ["The extent and frequency of transit service."],
    "LEVELS": [
      {
        "NAME": ["1"],
        "LABEL": ["Base"],
        "DESCRIPTION": ["Current public transit service level."]
      },
      {
        "NAME": ["2"],
        "LABEL": ["Double"],
        "DESCRIPTION": ["Double public transit service level."]
      },
      {
        "NAME": ["3"],
        "LABEL": ["Triple"],
        "DESCRIPTION": ["Triple public transit service level."]
      }
    ]
  },
  {
    "NAME": ["C"],
    "LABEL": ["Vehicle Travel Cost"],
    "DESCRIPTION": ["Combination of fuel prices and charges to pay for roadway costs and possibly externalities."],
    "INSTRUCTIONS": ["The combination of fuel prices and vehicle travel charges to pay for roadways and to pay for externalities such as carbon pricing."],
    "LEVELS": [
      {
        "NAME": ["1"],
        "LABEL": ["Base"],
        "DESCRIPTION": ["No change in fuel prices or increase in roadway or externality charges."]
      },
      {
        "NAME": ["2"],
        "LABEL": ["5 cents/mile"],
        "DESCRIPTION": ["Extra charge of 5 cents per mile. Equivalent to increase of fuel price of $1.00 per gallon for vehicles getting 20 MPG."]
      },
      {
        "NAME": ["3"],
        "LABEL": ["9 cents/mile"],
        "DESCRIPTION": ["Extra charge of 9 cents per mile. Equivalent to increase of fuel price of $2.25 per gallon for vehicles getting 50 MPG."]
      }
    ]
  }
];
