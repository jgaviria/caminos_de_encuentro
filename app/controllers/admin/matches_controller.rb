class Admin::MatchesController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin

  def index
    @matches = Match.includes(:user, :search_profile, search_profile: :user)
                   .order(similarity_score: :desc, created_at: :desc)

    # Add filtering options
    @matches = @matches.where(is_verified: params[:verified]) if params[:verified].present?
    @matches = @matches.where("similarity_score >= ?", params[:min_score]) if params[:min_score].present?

    # Add search functionality
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @matches = @matches.joins(:search_profile, search_profile: :user)
                        .joins("LEFT JOIN personal_infos ON personal_infos.user_id = matches.user_id")
                        .where("search_profiles.first_name ILIKE ? OR search_profiles.last_name ILIKE ? OR users.email ILIKE ? OR personal_infos.first_name ILIKE ? OR personal_infos.last_name ILIKE ?",
                               search_term, search_term, search_term, search_term, search_term)
    end

    @matches = @matches.page(params[:page]).per(20)

    # Statistics for dashboard
    @stats = {
      total_matches: Match.count,
      verified_matches: Match.where(is_verified: true).count,
      pending_matches: Match.where(is_verified: false).count,
      high_confidence_matches: Match.where("similarity_score >= 0.8").count,
      recent_matches: Match.where("created_at >= ?", 1.week.ago).count
    }

    # Handle JSON requests for AJAX
    respond_to do |format|
      format.html
      format.json do
        render json: {
          html: render_to_string(partial: "admin/matches/table_content", locals: { matches: @matches }, formats: [ :html ]),
          count: @matches.total_count
        }
      end
    end
  end

  def show
    @match = Match.find(params[:id])
    @search_profile = @match.search_profile
    @matched_user = @match.user
  end

  def verify
    @match = Match.find(params[:id])
    @match.update(is_verified: true)

    redirect_to admin_match_path(@match), notice: "Match verified successfully."
  end

  def reject
    @match = Match.find(params[:id])
    @match.destroy

    redirect_to admin_matches_path, notice: "Match rejected and removed."
  end

  def bulk_verify
    match_ids = params[:match_ids] || []
    Match.where(id: match_ids).update_all(is_verified: true)

    redirect_to admin_matches_path, notice: "#{match_ids.size} matches verified."
  end

  def bulk_reject
    match_ids = params[:match_ids] || []
    Match.where(id: match_ids).destroy_all

    redirect_to admin_matches_path, notice: "#{match_ids.size} matches rejected."
  end

  def export
    @matches = Match.includes(:user, :search_profile, search_profile: :user)

    respond_to do |format|
      format.csv do
        csv_data = generate_csv(@matches)
        send_data csv_data, filename: "matches_export_#{Date.current}.csv"
      end
    end
  end

  private

  def ensure_admin
    unless current_user.admin?
      redirect_to root_path, alert: "Access denied. Admin privileges required."
    end
  end

  def generate_csv(matches)
    require "csv"

    CSV.generate(headers: true) do |csv|
      csv << [
        "Match ID", "Search Profile ID", "Seeker Name", "Seeker Email",
        "Matched User ID", "Matched Name", "Matched Email",
        "Similarity Score", "Verified", "Created At"
      ]

      matches.each do |match|
        csv << [
          match.id,
          match.search_profile.id,
          "#{match.search_profile.first_name} #{match.search_profile.last_name}",
          match.search_profile.user.email,
          match.user&.id,
          match.user ? "#{match.user.personal_info&.first_name} #{match.user.personal_info&.last_name}" : "N/A",
          match.user&.email,
          match.similarity_score,
          match.is_verified,
          match.created_at
        ]
      end
    end
  end
end
