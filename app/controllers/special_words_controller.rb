# -*- encoding: utf-8 -*-
class SpecialWordsController < ApplicationController
  # GET /special_words
  # GET /special_words.json
  def list
    @special_words = SpecialWord.where(deleted: 0).page(params[:page]).per(50)

    respond_to do |format|
      format.html # listhtml.erb
      format.json { render json: @special_words }
    end
  end

  # GET /special_words/1
  # GET /special_words/1.json
  def show
    @special_word = SpecialWord.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @special_word }
    end
  end

  # GET /special_words/new
  # GET /special_words/new.json
  def new
    @special_word = SpecialWord.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @special_word }
    end
  end

  # GET /special_words/1/edit
  def edit
    @special_word = SpecialWord.find(params[:id])
  end

  # POST /special_words
  # POST /special_words.json
  def create
    @special_word = SpecialWord.new(params[:special_word])
    set_user_column @special_word

    respond_to do |format|
      begin
        @special_word.save!
        format.html { redirect_to :action => 'list', notice: 'Special word was successfully created.' }
        format.json { render json: @special_word, status: :created, location: @special_word }
      rescue ActiveRecord::RecordInvalid
        format.html { render action: "new" }
        format.json { render json: @special_word.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /special_words/1
  # PUT /special_words/1.json
  def update
    @special_word = SpecialWord.find(params[:id])
    @special_word.attributes = params[:special_word]
    set_user_column @special_word

    respond_to do |format|
      begin
        @special_word.save!
        format.html { redirect_to :action => 'list', notice: 'Special word was successfully updated.' }
        format.json { head :no_content }
      rescue ActiveRecord::RecordInvalid
        format.html { render action: "edit" }
        format.json { render json: @special_word.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /special_words/1
  # DELETE /special_words/1.json
  def destroy
    @special_word = SpecialWord.find(params[:id])
    @special_word.deleted = 9
    set_user_column @special_word
    @special_word.save!
    
    respond_to do |format|
      format.html { redirect_to :action => 'list' }
      format.json { head :no_content }
    end
  end
end
