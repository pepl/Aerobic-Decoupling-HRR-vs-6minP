# %HRR vs %6min MPP GarminIQ data field

## Background

The relation between %HRR and %6min MPP is a good indicator for aerobic decoupling for training session.

Checkout Stephen Seilers video on [Long, low intensity endurance sessions](https://www.youtube.com/watch?v=3GXc474Hu5U)

## Implementation

The decoupling ratio is calculated along a rolling window of about ten minutes. Generally, if it rises above **1.3** you should think about intensity and duration of the current activity if it was planned as LIT.

## Usage

Install from the GarminIQ store to your device and configure at least your individual 6 minute Mean Maximal Power settings value.