require 'cute_pets/pet_fetcher'
require 'minitest/autorun'
require 'webmock/minitest'
require 'vcr'

describe 'PetFetcher' do
  VCR.configure do |c|
    c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
    c.hook_into :webmock
  end

  describe '.get_petfinder_pet' do
    it 'returns a hash of pet data when the API request is successful' do
      ENV['petfinder_key'] = 'your_petfinder_key_goes_here'
      ENV['petfinder_shelter_id'] = 'shelter_id_goes_here'
      VCR.use_cassette('petfinder', record: :once) do
        pet_hash = PetFetcher.get_petfinder_pet
        pet_hash[:description].must_equal 'altered male ferret'
        pet_hash[:pic].must_equal 'http://photos.petfinder.com/photos/pets/30078059/1/?bust=1409196072&width=500&-x.jpg'
        pet_hash[:link].must_equal 'https://www.petfinder.com/petdetail/30078059'
        pet_hash[:name].must_equal 'Joey'
      end
    end

    it 'raises when the API request fails' do
      stub_request(:get, %r{^http\://api\.petfinder\.com/pet\.getRandom}).to_return(status: 500)
      -> { PetFetcher.get_petfinder_pet }.must_raise RuntimeError
    end
  end

  describe '.get_petharbor_pet' do
    it 'returns a hash of pet data when the request is successful' do
      PetFetcher.stub(:get_petharbor_pet_type, 'dog') do
        VCR.use_cassette('petharbor', record: :once) do
          pet_hash = PetFetcher.get_petharbor_pet
          pet_hash[:description].must_equal 'neutered male white bichon frise'
          pet_hash[:pic].must_equal 'http://www.PetHarbor.com/get_image.asp?RES=Thumb&ID=A223117&LOCATION=DNVR'
          # rubocop:disable LineLength
          pet_hash[:link].must_equal 'http://www.PetHarbor.com/detail.asp?ID=A223117&LOCATION=DNVR&searchtype=rnd&shelterlist=\'DNVR\'&where=dummy&kiosk=1'
          pet_hash[:name].must_equal 'Morty'
        end
      end
    end
  end

  it 'raises when the request fails' do
    stub_request(:get, %r{^http\://www\.petharbor\.com/petoftheday\.asp}).to_return(status: 500)
    -> { PetFetcher.get_petharbor_pet }.must_raise RuntimeError
  end

  describe 'get_petfinder_option' do
    it 'uses friendly values' do
      PetFetcher.send(:get_petfinder_option, 'option' => { '$t' => 'housebroken' }).must_equal 'house trained'
      PetFetcher.send(:get_petfinder_option, 'option' => { '$t' => 'housetrained' }).must_equal 'house trained'
      PetFetcher.send(:get_petfinder_option, 'option' => { '$t' => 'noClaws' }).must_equal 'declawed'
      PetFetcher.send(:get_petfinder_option, 'option' => { '$t' => 'altered' }).must_equal 'altered'
    end

    it 'handles multiple values in the options hash' do
      PetFetcher.send(:get_petfinder_option,
                      'option' => [{ '$t' => 'hasShots' },
                                   { '$t' => 'noClaws' }]).must_equal 'declawed'
    end

    it 'ignores some possible values' do
      PetFetcher.send(:get_petfinder_option,
                      'option' => [{ '$t' => 'hasShots' },
                                   { '$t' => 'noCats' },
                                   { '$t' => 'noDogs' },
                                   { '$t' => 'noKids' },
                                   { '$t' => 'totally not in the xsd' }]).must_equal nil
    end
  end

  describe 'get_petfinder_breed' do
    it 'works with a single hash' do
      PetFetcher.send(:get_petfinder_breed, 'breed' => { '$t' => 'Spaniel' }).must_equal 'Spaniel'
    end

    it 'works with an array of hashes' do
      PetFetcher.send(:get_petfinder_breed, 'breed' => [{ '$t' => 'Spaniel' }, { '$t' => 'Pomeranian' }]) \
                .must_equal 'Spaniel/Pomeranian mix'
    end
  end
end
