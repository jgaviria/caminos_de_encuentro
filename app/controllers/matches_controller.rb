# app/controllers/matches_controller.rb

class MatchesController < ApplicationController
  before_action :authenticate_user!
  
  def index
    # Show matches relevant to current user (either their search profiles or matches for them)
    search_profile_matches = Match.joins(:search_profile)
                                 .where(search_profiles: { user_id: current_user.id })
                                 .includes(:user, :search_profile)
    
    profile_matches = Match.where(user_id: current_user.id)
                          .includes(:search_profile, search_profile: :user)
    
    # Combine both types of matches
    @matches = (search_profile_matches + profile_matches)
              .uniq
              .sort_by { |match| [-match.similarity_score, -match.created_at.to_i] }
  end
  
  def show
    @match = Match.find(params[:id])
    # Ensure user can only see their own matches
    unless can_view_match?(@match)
      redirect_to matches_path, alert: "You don't have permission to view this match."
      return
    end
  end
  
  def verify
    @match = Match.find(params[:id])
    
    if can_verify_match?(@match)
      @match.update(is_verified: true)
      redirect_to @match, notice: "Match has been verified."
    else
      redirect_to matches_path, alert: "You don't have permission to verify this match."
    end
  end
  
  def destroy
    @match = Match.find(params[:id])
    
    if can_manage_match?(@match)
      @match.destroy
      redirect_to matches_path, notice: "Match has been removed."
    else
      redirect_to matches_path, alert: "You don't have permission to remove this match."
    end
  end
  
  private
  
  def can_view_match?(match)
    # User can view if it's their search profile or they are the matched user
    match.search_profile.user_id == current_user.id || match.user_id == current_user.id
  end
  
  def can_verify_match?(match)
    # Only admin users or the search profile owner can verify matches
    current_user.admin? || match.search_profile.user_id == current_user.id
  end
  
  def can_manage_match?(match)
    # Only admin users or the search profile owner can manage matches
    current_user.admin? || match.search_profile.user_id == current_user.id
  end
end
