
public class PhotoPage : Page {
    public static const Gdk.InterpType DEFAULT_INTERP = Gdk.InterpType.BILINEAR;
    public static const int IMAGE_BORDER = 4;
    
    private PhotoTable photoTable = new PhotoTable();
    private Gtk.Viewport viewport = new Gtk.Viewport(null, null);
    private Gtk.Toolbar toolbar = new Gtk.Toolbar();
    private Gtk.ToolButton rotateButton = null;
    private Gtk.Image image = new Gtk.Image();
    private PhotoExif exif = null;
    private Gdk.Pixbuf original = null;
    private Exif.Orientation orientation;
    private Gdk.Pixbuf rotated = null;
    private Dimensions rotatedDim;
    private Thumbnail thumbnail = null;
    private Page returnPage = null;

    // TODO: Mark fields for translation
    private const Gtk.ActionEntry[] ACTIONS = {
        { "FileMenu", null, "_File", null, null, null },

        { "PhotoMenu", null, "_Photo", null, null, null },        
        { "RotateClockwise", STOCK_CLOCKWISE, "Rotate c_lockwise", "<Ctrl>R", "Rotate the selected photos clockwise", on_rotate_clockwise },
        { "RotateCounterclockwise", STOCK_COUNTERCLOCKWISE, "Rotate c_ounterclockwise", "<Ctrl><Shift>R", "Rotate the selected photos counterclockwise", on_rotate_counterclockwise },
        { "Mirror", null, "_Mirror", "<Ctrl>M", "Make mirror images of the selected photos", on_mirror },

        { "HelpMenu", null, "_Help", null, null, null }
    };
    
    construct {
        init_ui("photo.ui", "/PhotoMenuBar", "PhotoActionGroup", ACTIONS);

        // set up page's toolbar (used by AppWindow for layout)
        //
        // rotate tool
        rotateButton = new Gtk.ToolButton.from_stock(STOCK_CLOCKWISE);
        rotateButton.label = "Rotate Clockwise";
        rotateButton.clicked += on_rotate_clockwise;
        toolbar.insert(rotateButton, -1);
        
        set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);

        viewport.add(image);
        viewport.modify_bg(Gtk.StateType.NORMAL, AppWindow.BG_COLOR);
        
        add(viewport);
        
        expose_event += on_expose;
    }
    
    public override Gtk.Toolbar get_toolbar() {
        return toolbar;
    }
    
    public void display_photo(PhotoID photoID, Page returnPage) {
        File file = photoTable.get_file(photoID);
        assert(file != null);
        
        debug("Loading %s", file.get_path());

        try {
            original = new Gdk.Pixbuf.from_file(file.get_path());
        } catch (Error err) {
            // TODO: Better error handling
            error("%s", err.message);
        }
        
        thumbnail = Thumbnail.get_existing(photoID);
        exif = PhotoExif.create(file);
        orientation = exif.get_orientation();
        rotated = rotate_to_exif(original, orientation);
        rotatedDim = Dimensions.for_pixbuf(rotated);
        this.returnPage = returnPage;
        
        repaint(true);
    }
    
    public void display_pixbuf(Gdk.Pixbuf pixbuf, Exif.Data exifData, Page returnPage) {
        Exif.Entry entry = Exif.find_first_entry(exifData, Exif.Tag.ORIENTATION, Exif.Format.SHORT);
        if (entry != null) {
            int o = Exif.Convert.get_short(entry.data, exifData.get_byte_order());
            assert(o >= Exif.ORIENTATION_MIN);
            assert(o <= Exif.ORIENTATION_MAX);
            
            orientation = (Exif.Orientation) o;
        } else {
            orientation = Exif.Orientation.TOP_LEFT;
        }

        original = pixbuf;
        thumbnail = null;
        exif = null;
        rotated = rotate_to_exif(original, orientation);
        rotatedDim = Dimensions.for_pixbuf(rotated);
        this.returnPage = returnPage;
        
        repaint(true);
    }

    private int lastWidth = 0;
    private int lastHeight = 0;
    
    private bool repaint(bool force = false) {
        int width = viewport.allocation.width - IMAGE_BORDER;
        int height = viewport.allocation.height - IMAGE_BORDER;

        if (width <= 0 || height <= 0)
            return false;

        if (!force && width == lastWidth && height == lastHeight)
            return false;

        lastWidth = width;
        lastHeight = height;
        
        Dimensions viewDim = Dimensions(width, height);
        Dimensions scaled = get_scaled_dimensions_for_view(rotatedDim, viewDim);
        Gdk.Pixbuf pixbuf = rotated.scale_simple(scaled.width, scaled.height, DEFAULT_INTERP);

        image.set_from_pixbuf(pixbuf);
        
        return true;
    }
    
    private override bool on_left_click(Gdk.EventButton event) {
        if (event.type == Gdk.EventType.2BUTTON_PRESS) {
            assert(returnPage != null);
            AppWindow.get_main_window().switch_to_page(returnPage);
            
            return true;
        }
        
        return false;
    }

    private bool on_expose(PhotoPage p, Gdk.EventExpose event) {
        return repaint();
    }
    
    private void set_orientation(Exif.Orientation newOrientation) {
        orientation = newOrientation;
        rotated = rotate_to_exif(original, orientation);
        rotatedDim = Dimensions.for_pixbuf(rotated);
        
        if (exif != null) {
            exif.set_orientation(orientation);

            try {
                exif.commit();
            } catch (Error err) {
                error("%s", err.message);
            }
        }
        
        if (thumbnail != null)
            thumbnail.refresh_exif();
        
        repaint(true);
    }
    
    private void on_rotate_clockwise() {
        set_orientation(orientation.rotate_clockwise());
    }
    
    private void on_rotate_counterclockwise() {
        set_orientation(orientation.rotate_counterclockwise());
    }
    
    private void on_mirror() {
        set_orientation(orientation.flip_left_to_right());
    }

    private override bool on_ctrl_pressed(Gdk.EventKey event) {
        rotateButton.set_stock_id(STOCK_COUNTERCLOCKWISE);
        rotateButton.label = "Rotate Counterclockwise";
        rotateButton.clicked -= on_rotate_clockwise;
        rotateButton.clicked += on_rotate_counterclockwise;
        
        return false;
    }
    
    private override bool on_ctrl_released(Gdk.EventKey event) {
        rotateButton.set_stock_id(STOCK_CLOCKWISE);
        rotateButton.label = "Rotate Clockwise";
        rotateButton.clicked -= on_rotate_counterclockwise;
        rotateButton.clicked += on_rotate_clockwise;
        
        return false;
    }
}

