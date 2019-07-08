class PoliesController < ApplicationController
  before_action :set_poly, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user!, except: [:index, :show]

  # GET /polies
  # GET /polies.json
  def index
    @polies = Poly.all
  end

  # GET /polies/1
  # GET /polies/1.json
  def show
  end

  # GET /polies/new
  def new
    @poly = current_user.polies.build
  end

  # GET /polies/1/edit
  def edit
  end

  # POST /polies
  # POST /polies.json
  def create
    @poly = current_user.polies.build(poly_params)

    respond_to do |format|
      if @poly.save
        format.html { redirect_to @poly, notice: 'Poly was successfully created.' }
        format.json { render :show, status: :created, location: @poly }
      else
        format.html { render :new }
        format.json { render json: @poly.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /polies/1
  # PATCH/PUT /polies/1.json
  def update
    respond_to do |format|
      if @poly.update(poly_params)
        format.html { redirect_to @poly, notice: 'Poly was successfully updated.' }
        format.json { render :show, status: :ok, location: @poly }
      else
        format.html { render :edit }
        format.json { render json: @poly.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /polies/1
  # DELETE /polies/1.json
  def destroy
    @poly.destroy
    respond_to do |format|
      format.html { redirect_to polies_url, notice: 'Poly was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_poly
      @poly = Poly.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def poly_params
      params.require(:poly).permit(:title, :image)
    end
end
