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
        "LABEL": ["EcoProp & ImpProp"],
        "DESCRIPTION": ["Increased the proportion by 10%"]
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
        "LABEL": ["Activity Center Growth"],
        "DESCRIPTION": ["LU overlaps with HHsize + Population."]
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
        "LABEL": ["Increase parking cost and proportion"],
        "DESCRIPTION": ["Increase parking cost by 100% and proportion charted by 10%."]
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
        "DESCRIPTION": ["Quadruple public transit service level."]
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
        "LABEL": ["Steady Ownership Cost/Tax"],
        "DESCRIPTION": ["Keep the vehicle ownerhsip cost the same."]
      },
      {
        "NAME": ["3"],
        "LABEL": ["Payd insurance and higher cost"],
        "DESCRIPTION": ["Higher climate cost and pay as you drive insurance."]
      }
    ]
  },
  {
    "NAME": ["V"],
    "LABEL": ["Vehicle Characteristics"],
    "DESCRIPTION": ["Proportions of light trucks and average vehicle age"],
    "INSTRUCTIONS": ["The combination of fuel prices and vehicle travel charges to pay for roadways and to pay for externalities such as carbon pricing."],
    "LEVELS": [
      {
        "NAME": ["1"],
        "LABEL": ["Base"],
        "DESCRIPTION": ["Light truck proportion remains 45% of the fleet and the average vehicle age remains 12 years."]
      },
      {
        "NAME": ["2"],
        "LABEL": ["Reduced"],
        "DESCRIPTION": ["Light truck proportion at 35% of the fleet and the average vehicle age at 8 years."]
      }
    ]
  },
  {
    "NAME": ["F"],
    "LABEL": ["Technology Mix and CI"],
    "DESCRIPTION": ["Vehicle technology mix and carbon intensity of fuels."],
    "INSTRUCTIONS": [""],
    "LEVELS": [
      {
        "NAME": ["1"],
        "LABEL": ["Base"],
        "DESCRIPTION": ["Baseline vehicle technology mix."]
      },
      {
        "NAME": ["2"],
        "LABEL": ["Higher Electric"],
        "DESCRIPTION": ["Increased percentage of electric vehicles in household and commercial setting by 20%."]
      }
    ]
  },
  {
    "NAME": ["E"],
    "LABEL": ["Driving Efficiency"],
    "DESCRIPTION": ["Driving efficiency by increasing implementation of ITS."],
    "INSTRUCTIONS": [""],
    "LEVELS": [
      {
        "NAME": ["1"],
        "LABEL": ["Base"],
        "DESCRIPTION": ["Baseline implementation of ITS."]
      },
      {
        "NAME": ["2"],
        "LABEL": ["Fully implemented ITS"],
        "DESCRIPTION": ["Increase the effectiveness of implementation of ITS."]
      }
    ]
  },
  {
    "NAME": ["G"],
    "LABEL": ["Fuel Price"],
    "DESCRIPTION": ["Real fuel price in 2010 USD."],
    "INSTRUCTIONS": [""],
    "LEVELS": [
      {
        "NAME": ["1"],
        "LABEL": ["Base"],
        "DESCRIPTION": ["Baseline fuel price."]
      },
      {
        "NAME": ["2"],
        "LABEL": ["Double fuel price"],
        "DESCRIPTION": ["Real fuel price doubles."]
      },
      {
        "NAME": ["3"],
        "LABEL": ["Quadruple fuel price"],
        "DESCRIPTION": ["Real fuel price quadruples."]
      }
    ]
  },
  {
    "NAME": ["I"],
    "LABEL": ["Income"],
    "DESCRIPTION": ["Real average household income in 2010 USD."],
    "INSTRUCTIONS": [""],
    "LEVELS": [
      {
        "NAME": ["1"],
        "LABEL": ["Base"],
        "DESCRIPTION": ["Baseline household income."]
      },
      {
        "NAME": ["2"],
        "LABEL": ["Income growth 1"],
        "DESCRIPTION": ["Income growth of 7% w.r.t reference."]
      },
      {
        "NAME": ["3"],
        "LABEL": ["Income growth 2"],
        "DESCRIPTION": ["Income growth of 14% w.r.t reference."]
      }
    ]
  }
];
