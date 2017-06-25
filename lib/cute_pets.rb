require './lib/cute_pets/pet_fetcher'
require './lib/cute_pets/tweet_generator'
require 'dotenv'
Dotenv.load

# Tie together the PetFinder/PetHarbor and the Twitter integrations
module CutePets
  extend self

  def post_pet
    pet = if ENV.fetch('pet_datasource').casecmp('petfinder').zero?
            PetFetcher.get_petfinder_pet
          else
            PetFetcher.get_petharbor_pet
          end

    return unless pet

    message = TweetGenerator.create_message(pet[:name], pet[:description], pet[:link])
    TweetGenerator.tweet(message, pet[:pic])
  end
end
