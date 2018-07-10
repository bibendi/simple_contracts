[![Build Status](https://travis-ci.com/bibendi/simple_contracts.svg?branch=master)](https://travis-ci.com/bibendi/simple_contracts)

# SimpleContracts

## Plain Old Ruby Object Implementation of Contract

This project contains the most simple implementation of Contract written in Ruby (and maybe later in other languages).

The Contract is inspired by Design by Contracts approach and pushes Fail Fast techinque further.

So, Contract is a class with the only public method , that validates some action/behavior agains Contract Rules:
 - Guarantees - the rules that SHOULD be valid for each check of behavior
 - Expectations - list of all expected states that COULD be valid for the behavior check

Contract validates, that:
 - ALL Guarantees were met
 - AT LEAST ONE Expectations was met

Otherwise, Contract raises an exception with details, at least on what step behavior was broken.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'simple_contracts'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install simple_contracts

## Usage

TODO: Write usage instructions here

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bibendi/simple_contracts.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
