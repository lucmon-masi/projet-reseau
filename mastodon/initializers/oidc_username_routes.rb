Rails.application.config.to_prepare do
  Rails.application.routes.draw do
    scope '/auth' do
      get  'choose_username', to: 'auth/choose_username#show',   as: :choose_username
      post 'choose_username', to: 'auth/choose_username#create'
    end
  end
end
