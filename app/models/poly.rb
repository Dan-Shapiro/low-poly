class Poly < ActiveRecord::Base
    belongs_to :user
    
    has_attached_file :image, styles: { medium: "400x400#", thumb: "100x100#" }
    validates_attachment_content_type :image, content_type: /\Aimage\/.*\z/
    
    after_save :polify_image
    
    protected
    def polify_image
        require 'opencv'
        require 'dlib'
        require 'ruby_vor'
        
        image_path = self.image.path
        temp_image = File.open("temp.jpg", "r")
        
        if File.basename(self.image.path) == File.basename(temp_image)
            return
        end
        
        original_image = OpenCV::CvMat.load(image_path)
        original_image = self.resize(original_image)
        
        smoothed_image = original_image.smooth(OpenCV::CV_GAUSSIAN)
        gray_image = smoothed_image.BGR2GRAY
        blurred_gray_image = gray_image.smooth(OpenCV::CV_GAUSSIAN, 5, 5, 3)
        sharp_gray_image = OpenCV::CvMat.add_weighted(gray_image, 2.5, blurred_gray_image, -1, 0)
        
        sharp_gray_image.save_image("s_gray.jpg")
        
        av_thresh = self.get_threshold(gray_image)
        low_thresh = 0.66 * av_thresh
        high_thresh = 1.33 * av_thresh
        
        draw_contours = self.get_contours(sharp_gray_image, low_thresh, high_thresh)
        
        ret_comp_points = self.triangulate(draw_contours)
        comp = ret_comp_points[0]
        points = ret_comp_points[1]
        
        tris = comp.delaunay_triangulation_raw
        
        poly_image = original_image
        tris.each do |tri|
            point_a = [points[tri[0]].x, points[tri[0]].y]
            point_b = [points[tri[1]].x, points[tri[1]].y]
            point_c = [points[tri[2]].x, points[tri[2]].y]
            
            poly_image = self.get_pixels_in_triangle(point_a, point_b, point_c, poly_image)
        end
        
        poly_image.save_image("temp.jpg")
        temp_image = File.open("temp.jpg", "r")
        self.update_attribute(:image, temp_image) unless File.basename(self.image.path) == File.basename(temp_image)
    end
    
    def get_threshold(gray_image)
        sum = 0
        iters = gray_image.dim_size(0) * gray_image.dim_size(1) * 3
        
        gray_image.dim_size(0).times do |row|
            gray_image.dim_size(1).times do |col|
                3.times do |i|
                    sum += gray_image[row * gray_image.dim_size(0) + col][i]
                end
            end
        end
        av = sum.to_f / iters.to_f
        return av
    end
    
    def get_contours(sharp_gray_image, low_thresh, high_thresh)
        edges = sharp_gray_image.canny(low_thresh, high_thresh)
        contour = edges.find_contours(:mode => OpenCV::CV_RETR_LIST, :method => OpenCV::CV_CHAIN_APPROX_SIMPLE)
        draw_contours = edges.draw_contours(contour, OpenCV::CvScalar::Black, OpenCV::CvScalar::White, 0)
        return draw_contours
    end
    
    def triangulate(draw_contours)
        draw_contours.save_image("contours.jpg")
        
        row_points = []
        col_points = []
        draw_contours.dim_size(0).times do |row|
            draw_contours.dim_size(1).times do |col|
                allzero = true
                3.times do |i|
                    allzero = false if draw_contours[row * draw_contours.dim_size(0) + col][i] > 0.0
                end
                unless allzero
                    row_points.push(row)
                    col_points.push(col)
                end
            end
        end
        
        c = 0.02
        num_points = (row_points.size * c).to_i
        
        nums = (0..row_points.size).to_a.shuffle
        rand_points = []
        num_points.times do |n|
            r = nums.pop
            rand_points.push([row_points[r], col_points[r]])
        end
        
        points = []
        rand_points.each do |pt|
            points.push(RubyVor::Point.new(pt[1], pt[0]))
        end
        
        points.push(RubyVor::Point.new(0, 0))
        points.push(RubyVor::Point.new(draw_contours.dim_size(0) - 1, 0))
        points.push(RubyVor::Point.new(0, draw_contours.dim_size(1) - 1))
        points.push(RubyVor::Point.new(draw_contours.dim_size(0) - 1, draw_contours.dim_size(1) - 1))
        
        comp = RubyVor::VDDT::Computation.from_points(points)
        return [comp, points]
    end
    
    def get_pixels_in_triangle(a, b, c, original_image)
        pixels = []
        
        min_x = [a[0], b[0], c[0]].min
        max_x = [a[0], b[0], c[0]].max
        min_y = [a[1], b[1], c[1]].min
        max_y = [a[1], b[1], c[1]].max
        
        x_range = (max_x - min_x + 1).to_i
        y_range = (max_y - min_y + 1).to_i
        
        y_range.times do |r|
            row = r + min_y
            x_range.times do |cl|
                col = cl + min_x
                loc = original_image.dim_size(0)*row + col
                pixel_rgb = [original_image[loc][0], original_image[loc][1], original_image[loc][2]]
                abc = triangle_area(a, b, c)
                pab = triangle_area([col, row], a, b)
                pbc = triangle_area([col, row], b, c)
                pca = triangle_area([col, row], c, a)
                
                pixels.push([loc, pixel_rgb]) if abc == pab + pbc + pca
            end
        end
        count = pixels.count
        
        if count == 0
             
        end
        
        red = 0
        green = 0
        blue = 0
        
        pixels.each do |pixel|
             red += pixel[1][0]
             green += pixel[1][1]
             blue += pixel[1][2]
        end
        
        red = (red.to_f / count.to_f).round
        green = (green.to_f / count.to_f).round
        blue = (blue.to_f / count.to_f).round
        
        new_image = original_image
        pixels.each do |pixel|
            new_image[pixel[0]] = [red, green, blue, 0.0]
        end
        
        return new_image
    end
    
    def triangle_area(a, b, c)
         return (((a[0]*(b[1]-c[1])) + (b[0]*(c[1]-a[1])) + (c[0]*(a[1]-b[1]))).to_f / 2.0).abs
    end
    
    def resize(original_image)
        size_400 = OpenCV::CvSize.new(400, 400)
        original_image = original_image.resize(size_400, OpenCV::CV_INTER_AREA) 
    end
end
