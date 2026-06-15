# frozen_string_literal: true

class Auth::ChooseUsernameController < ApplicationController
  layout 'auth'

  before_action :require_pending_oidc_auth

  def show
    @suggested = suggested_username
    @role      = detect_role
  end

  def create
    username = params[:username].to_s.strip.downcase.gsub(/[^a-z0-9_]/, '')

    if username.blank?
      flash.now[:alert] = "Le nom d'utilisateur ne peut pas être vide."
      @suggested = suggested_username
      @role      = detect_role
      render :show and return
    end

    if username.length > 30
      flash.now[:alert] = "Le nom d'utilisateur ne peut pas dépasser 30 caractères."
      @suggested = suggested_username
      @role      = detect_role
      render :show and return
    end

    if Account.exists?(username: username, domain: nil)
      flash.now[:alert] = "Ce nom d'utilisateur est déjà pris."
      @suggested = suggested_username
      @role      = detect_role
      render :show and return
    end

    auth_data = session[:pending_oidc_auth]
    identity  = Identity.find_or_initialize_by(provider: auth_data['provider'], uid: auth_data['uid'])

    user = User.new(
      email:     auth_data['email'] || "change@me-#{auth_data['uid']}-#{auth_data['provider']}.com",
      agreement: true,
      external:  true,
      account_attributes: {
        username:     username,
        display_name: auth_data['name'] || "#{auth_data['first_name']} #{auth_data['last_name']}",
      },
    )

    begin
      user.mark_email_as_confirmed!
      user.save!
      identity.user = user
      identity.save!

      session[:oidc_id_token] = auth_data['id_token']
      session.delete(:pending_oidc_auth)

      # Sync du rôle
      raw_roles = Array(auth_data['roles'])
      role_map  = { 'teacher' => 'Admin', 'tutor' => 'Moderator', 'student' => 'User' }
      role_name = role_map.find { |k, _| raw_roles.include?(k) }&.last || 'User'
      role      = UserRole.find_by(name: role_name)
      user.update_column(:role_id, role.id) if role

      # Sauvegarde des custom fields sur le profil
      save_profile_fields(user.account, raw_roles)

      # Message de bienvenue automatique depuis l'admin
      post_welcome_message(user.account, raw_roles)

      sign_in(user, event: :authentication)
      redirect_to root_path
    rescue ActiveRecord::RecordInvalid => e
      flash.now[:alert] = "Erreur : #{e.message}"
      @suggested = username
      @role      = detect_role
      render :show
    end
  end

  private

  def require_pending_oidc_auth
    redirect_to new_user_session_path unless session[:pending_oidc_auth]
  end

  def detect_role
    raw_roles = Array(session.dig(:pending_oidc_auth, 'roles'))
    return 'teacher' if raw_roles.include?('teacher')
    return 'tutor'   if raw_roles.include?('tutor')
    'student'
  end

  def suggested_username
    auth_data = session[:pending_oidc_auth]
    first     = auth_data&.[]('first_name').to_s.downcase.gsub(/[^a-z0-9]/, '')
    last      = auth_data&.[]('last_name').to_s.downcase.gsub(/[^a-z0-9]/, '')
    base      = "#{first[0..2]}#{last[0..2]}"
    base      = 'user' if base.blank?
    candidate = base
    i         = 0
    while Account.exists?(username: candidate, domain: nil)
      i        += 1
      candidate = "#{base}#{i}"
    end
    candidate
  end

  def post_welcome_message(new_account, raw_roles)
    admin = Account.local.joins(:user)
                   .merge(User.where(role_id: UserRole.where(name: 'Admin').select(:id)))
                   .first
    return unless admin

    role_label = if raw_roles.include?('teacher')
                   "enseignant(e) 🎓"
                 elsif raw_roles.include?('tutor')
                   "tuteur/tutrice 📚"
                 else
                   "étudiant(e) 👋"
                 end

    tip = if raw_roles.include?('teacher')
            "Vous pouvez poster des annonces et gérer la communauté depuis le panneau d'administration."
          elsif raw_roles.include?('tutor')
            "Pensez à renseigner vos matières et disponibilités dans vos paramètres de profil !"
          else
            "Suivez vos tuteurs et utilisez les hashtags de matière pour trouver des ressources. #Tutorat"
          end

    PostStatusService.new.call(
      admin,
      text:       "Bienvenue sur le réseau Hénallux, @#{new_account.username} ! 🎉\n\n" \
                  "Tu rejoins la communauté en tant que #{role_label}.\n#{tip}\n\n#Hénallux #Bienvenue",
      visibility: :public,
    )
  rescue => e
    Rails.logger.warn("[ChooseUsername] welcome message failed: #{e.message}")
  end

  def save_profile_fields(account, raw_roles)
    fields = []

    matieres = params[:field_matieres].to_s.strip
    dispos   = params[:field_dispos].to_s.strip
    annee    = params[:field_annee].to_s.strip

    if raw_roles.include?('teacher')
      fields << { name: 'Matière(s)', value: matieres } if matieres.present?
      fields << { name: 'Année',      value: annee }     if annee.present?
    elsif raw_roles.include?('tutor')
      fields << { name: 'Matière(s)',      value: matieres } if matieres.present?
      fields << { name: 'Disponibilités',  value: dispos }   if dispos.present?
    elsif raw_roles.include?('student')
      fields << { name: 'Année',           value: annee }    if annee.present?
      fields << { name: 'Aide souhaitée',  value: matieres } if matieres.present?
    end

    return if fields.empty?

    account.update!(fields_attributes: fields.each_with_index.map { |f, i| [i.to_s, f] }.to_h)
  rescue => e
    Rails.logger.warn("ChooseUsername: impossible de sauvegarder les fields: #{e.message}")
  end
end
