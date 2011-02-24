/* Copyright 2009-2011 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution. 
 */

public class DirectPhotoPage : EditingHostPage {
    private Gtk.Menu context_menu;
    private File initial_file;
    private DirectViewCollection? view_controller = null;
    private File current_save_dir;
    private bool drop_if_dirty = false;
    
    public DirectPhotoPage(File file) {
        base (DirectPhoto.global, file.get_basename());
        
        if (!check_editable_file(file)) {
            Application.get_instance().panic();
            
            return;
        }
        
        initial_file = file;
        view_controller = new DirectViewCollection(initial_file);
        current_save_dir = file.get_parent();
        
        context_menu = (Gtk.Menu) ui.get_widget("/DirectContextMenu");
        
        DirectPhoto.global.items_altered.connect(on_photos_altered);
        
        get_view().selection_group_altered.connect(on_selection_group_altered);
    }
    
    ~DirectPhotoPage() {
        DirectPhoto.global.items_altered.disconnect(on_photos_altered);
    }
    
    protected override void init_collect_ui_filenames(Gee.List<string> ui_filenames) {
        base.init_collect_ui_filenames(ui_filenames);
        
        ui_filenames.add("direct.ui");
    }
    
    protected override Gtk.ActionEntry[] init_collect_action_entries() {
        Gtk.ActionEntry[] actions = base.init_collect_action_entries();
        
        Gtk.ActionEntry file = { "FileMenu", null, TRANSLATABLE, null, null, null };
        file.label = _("_File");
        actions += file;

        Gtk.ActionEntry save = { "Save", Gtk.STOCK_SAVE, TRANSLATABLE, "<Ctrl>S", TRANSLATABLE,
            on_save };
        save.label = _("_Save");
        save.tooltip = _("Save photo");
        actions += save;

        Gtk.ActionEntry save_as = { "SaveAs", Gtk.STOCK_SAVE_AS, TRANSLATABLE,
            "<Ctrl><Shift>S", TRANSLATABLE, on_save_as };
        save_as.label = _("Save _As...");
        save_as.tooltip = _("Save photo with a different name");
        actions += save_as;
        
        Gtk.ActionEntry send_to = { "SendTo", "document-send", TRANSLATABLE, null,
            TRANSLATABLE, on_send_to };
        send_to.label = Resources.SEND_TO_MENU;
        send_to.tooltip = Resources.SEND_TO_TOOLTIP;
        actions += send_to;

        Gtk.ActionEntry print = { "Print", Gtk.STOCK_PRINT, TRANSLATABLE, "<Ctrl>P",
            TRANSLATABLE, on_print };
        print.label = Resources.PRINT_MENU;
        print.tooltip = _("Print the photo to a printer connected to your computer");
        actions += print;
        
        Gtk.ActionEntry edit = { "EditMenu", null, TRANSLATABLE, null, null, null };
        edit.label = _("Edit");
        actions += edit;

        Gtk.ActionEntry photo = { "PhotoMenu", null, "", null, null, null };
        photo.label = _("_Photo");
        actions += photo;
        
        Gtk.ActionEntry tools = { "Tools", null, TRANSLATABLE, null, null, null };
        tools.label = _("_Tools");
        actions += tools;
        
        Gtk.ActionEntry prev = { "PrevPhoto", Gtk.STOCK_GO_BACK, TRANSLATABLE, null,
            TRANSLATABLE, on_previous_photo };
        prev.label = _("_Previous Photo");
        prev.tooltip = _("Previous Photo");
        actions += prev;

        Gtk.ActionEntry next = { "NextPhoto", Gtk.STOCK_GO_FORWARD, TRANSLATABLE, null,
            TRANSLATABLE, on_next_photo };
        next.label = _("_Next Photo");
        next.tooltip = _("Next Photo");
        actions += next;

        Gtk.ActionEntry rotate_right = { "RotateClockwise", Resources.CLOCKWISE,
            TRANSLATABLE, "<Ctrl>R", TRANSLATABLE, on_rotate_clockwise };
        rotate_right.label = Resources.ROTATE_CW_MENU;
        rotate_right.tooltip = Resources.ROTATE_CCW_TOOLTIP;
        actions += rotate_right;

        Gtk.ActionEntry rotate_left = { "RotateCounterclockwise", Resources.COUNTERCLOCKWISE,
            TRANSLATABLE, "<Ctrl><Shift>R", TRANSLATABLE, on_rotate_counterclockwise };
        rotate_left.label = Resources.ROTATE_CCW_MENU;
        rotate_left.tooltip = Resources.ROTATE_CCW_TOOLTIP;
        actions += rotate_left;

        Gtk.ActionEntry hflip = { "FlipHorizontally", Resources.HFLIP, TRANSLATABLE, null,
            TRANSLATABLE, on_flip_horizontally };
        hflip.label = Resources.HFLIP_MENU;
        hflip.tooltip = Resources.HFLIP_TOOLTIP;
        actions += hflip;
        
        Gtk.ActionEntry vflip = { "FlipVertically", Resources.VFLIP, TRANSLATABLE, null,
            TRANSLATABLE, on_flip_vertically };
        vflip.label = Resources.VFLIP_MENU;
        vflip.tooltip = Resources.VFLIP_TOOLTIP;
        actions += vflip;
        
        Gtk.ActionEntry enhance = { "Enhance", Resources.ENHANCE, TRANSLATABLE, "<Ctrl>E",
            TRANSLATABLE, on_enhance };
        enhance.label = Resources.ENHANCE_MENU;
        enhance.tooltip = Resources.ENHANCE_TOOLTIP;
        actions += enhance;
        
        Gtk.ActionEntry crop = { "Crop", Resources.CROP, TRANSLATABLE, "<Ctrl>O",
            TRANSLATABLE, toggle_crop };
        crop.label = Resources.CROP_MENU;
        crop.tooltip = Resources.CROP_TOOLTIP;
        actions += crop;
        
        Gtk.ActionEntry red_eye = { "RedEye", Resources.REDEYE, TRANSLATABLE, "<Ctrl>Y",
            TRANSLATABLE, toggle_redeye };
        red_eye.label = Resources.RED_EYE_MENU;
        red_eye.tooltip = Resources.RED_EYE_TOOLTIP;
        actions += red_eye;
        
        Gtk.ActionEntry adjust = { "Adjust", Resources.ADJUST, TRANSLATABLE, "<Ctrl>D",
            TRANSLATABLE, toggle_adjust };
        adjust.label = Resources.ADJUST_MENU;
        adjust.tooltip = Resources.ADJUST_TOOLTIP;
        actions += adjust;
        
        Gtk.ActionEntry revert = { "Revert", Gtk.STOCK_REVERT_TO_SAVED, TRANSLATABLE,
            null, TRANSLATABLE, on_revert };
        revert.label = Resources.REVERT_MENU;
        revert.tooltip = Resources.REVERT_TOOLTIP;
        actions += revert;

        Gtk.ActionEntry adjust_date_time = { "AdjustDateTime", null, TRANSLATABLE, null,
            TRANSLATABLE, on_adjust_date_time };
        adjust_date_time.label = Resources.ADJUST_DATE_TIME_MENU;
        adjust_date_time.tooltip = Resources.ADJUST_DATE_TIME_TOOLTIP;
        actions += adjust_date_time;
        
        Gtk.ActionEntry set_background = { "SetBackground", null, TRANSLATABLE, "<Ctrl>B",
            TRANSLATABLE, on_set_background };
        set_background.label = Resources.SET_BACKGROUND_MENU;
        set_background.tooltip = Resources.SET_BACKGROUND_TOOLTIP;
        actions += set_background;

        Gtk.ActionEntry view = { "ViewMenu", null, TRANSLATABLE, null, null, null };
        view.label = _("_View");
        actions += view;

        Gtk.ActionEntry help = { "HelpMenu", null, TRANSLATABLE, null, null, null };
        help.label = _("_Help");
        actions += help;

        Gtk.ActionEntry increase_size = { "IncreaseSize", Gtk.STOCK_ZOOM_IN, TRANSLATABLE,
            "<Ctrl>plus", TRANSLATABLE, on_increase_size };
        increase_size.label = _("Zoom _In");
        increase_size.tooltip = _("Increase the magnification of the photo");
        actions += increase_size;

        Gtk.ActionEntry decrease_size = { "DecreaseSize", Gtk.STOCK_ZOOM_OUT, TRANSLATABLE,
            "<Ctrl>minus", TRANSLATABLE, on_decrease_size };
        decrease_size.label = _("Zoom _Out");
        decrease_size.tooltip = _("Decrease the magnification of the photo");
        actions += decrease_size;

        Gtk.ActionEntry best_fit = { "ZoomFit", Gtk.STOCK_ZOOM_FIT, TRANSLATABLE,
            "<Ctrl>0", TRANSLATABLE, snap_zoom_to_min };
        best_fit.label = _("Fit to _Page");
        best_fit.tooltip = _("Zoom the photo to fit on the screen");
        actions += best_fit;

        Gtk.ActionEntry actual_size = { "Zoom100", Gtk.STOCK_ZOOM_100, TRANSLATABLE,
            "<Ctrl>1", TRANSLATABLE, snap_zoom_to_isomorphic };
        actual_size.label = _("Zoom _100%");
        actual_size.tooltip = _("Zoom the photo to 100% magnification");
        actions += actual_size;
        
        Gtk.ActionEntry max_size = { "Zoom200", null, TRANSLATABLE,
            "<Ctrl>2", TRANSLATABLE, snap_zoom_to_max };
        max_size.label = _("Zoom _200%");
        max_size.tooltip = _("Zoom the photo to 200% magnification");
        actions += max_size;

        return actions;
    }
    
    protected override InjectionGroup[] init_collect_injection_groups() {
        InjectionGroup[] groups = base.init_collect_injection_groups();
        
        InjectionGroup print_group = new InjectionGroup("/MenuBar/FileMenu/PrintPlaceholder");
        print_group.add_menu_item("Print");
        
        groups += print_group;
        
        InjectionGroup bg_group = new InjectionGroup("/MenuBar/FileMenu/SetBackgroundPlaceholder");
        bg_group.add_menu_item("SetBackground");
        
        groups += bg_group;
        
        return groups;
    }
    
    private static bool check_editable_file(File file) {
        if (!FileUtils.test(file.get_path(), FileTest.EXISTS))
            AppWindow.error_message(_("%s does not exist.").printf(file.get_path()));
        else if (!FileUtils.test(file.get_path(), FileTest.IS_REGULAR))
            AppWindow.error_message(_("%s is not a file.").printf(file.get_path()));
        else if (!PhotoFileFormat.is_file_supported(file))
            AppWindow.error_message(_("%s does not support the file format of\n%s.").printf(
                Resources.APP_TITLE, file.get_path()));
        else
            return true;
        
        return false;
    }
    
    public override void realize() {
        if (base.realize != null)
            base.realize();
        
        DirectPhoto? photo = null;
        
        DirectPhotoPlaceholder? placeholder = DirectPhotoPlaceholder.global.get_source_for_file(initial_file);
        if (placeholder != null)
            photo = placeholder.fetch_real_source() as DirectPhoto;
        
        if (photo == null || photo is DummyDirectPhoto) {
            AppWindow.error_message(_("Unable to load %s: %s").printf(initial_file.get_path(),
                ((DummyDirectPhoto) photo).get_reason()));
            
            Application.get_instance().panic();
            
            return;
        }
        
        display_mirror_of(view_controller, photo);
        initial_file = null;
    }
    
    public File get_current_file() {
        return get_photo().get_file();
    }

    protected override bool on_context_buttonpress(Gdk.EventButton event) {
        popup_context_menu(context_menu, event);

        return true;
    }

    private void update_zoom_menu_item_sensitivity() {
        set_action_sensitive("IncreaseSize", !get_zoom_state().is_max() && !get_photo_missing());
        set_action_sensitive("DecreaseSize", !get_zoom_state().is_default() && !get_photo_missing());
    }

    protected override void on_increase_size() {
        base.on_increase_size();
        
        update_zoom_menu_item_sensitivity();
    }
    
    protected override void on_decrease_size() {
        base.on_decrease_size();

        update_zoom_menu_item_sensitivity();
    }
    
    private void on_photos_altered(Gee.Map<DataObject, Alteration> map) {
        bool contains = false;
        if (has_photo()) {
            Photo photo = get_photo();
            foreach (DataObject object in map.keys) {
                if (((Photo) object) == photo) {
                    contains = true;
                    
                    break;
                }
            }
        }
        
        bool sensitive = has_photo() && !get_photo_missing();
        if (sensitive)
            sensitive = contains;
        
        set_action_sensitive("Save", sensitive && get_photo().get_file_format().can_write());
        set_action_sensitive("Revert", sensitive);
    }
    
    private void on_selection_group_altered() {
        // On EditingHostPage, the displayed photo is always selected, so this signal is fired
        // whenever a new photo is displayed (which even happens on an in-place save; the changes
        // are written and a new DirectPhoto is loaded into its place).
        //
        // In every case, reset the CommandManager, as the command stack is not valid against this
        // new file.
        get_command_manager().reset();
    }
    
    protected override void update_ui(bool missing) {
        bool sensitivity = !missing;
        
        set_action_sensitive("Save", sensitivity);
        set_action_sensitive("SaveAs", sensitivity);
        set_action_sensitive("SendTo", sensitivity);
        set_action_sensitive("Publish", sensitivity);
        set_action_sensitive("Print", sensitivity);
        set_action_sensitive("CommonJumpToFile", sensitivity);
        
        set_action_sensitive("CommonUndo", sensitivity);
        set_action_sensitive("CommonRedo", sensitivity);
        
        set_action_sensitive("IncreaseSize", sensitivity);
        set_action_sensitive("DecreaseSize", sensitivity);
        set_action_sensitive("ZoomFit", sensitivity);
        set_action_sensitive("Zoom100", sensitivity);
        set_action_sensitive("Zoom200", sensitivity);
        
        set_action_sensitive("RotateClockwise", sensitivity);
        set_action_sensitive("RotateCounterclockwise", sensitivity);
        set_action_sensitive("FlipHorizontally", sensitivity);
        set_action_sensitive("FlipVertically", sensitivity);
        set_action_sensitive("Enhance", sensitivity);
        set_action_sensitive("Crop", sensitivity);
        set_action_sensitive("RedEye", sensitivity);
        set_action_sensitive("Adjust", sensitivity);
        set_action_sensitive("Revert", sensitivity);
        set_action_sensitive("AdjustDateTime", sensitivity);
        set_action_sensitive("Fullscreen", sensitivity);
        
        set_action_sensitive("SetBackground", has_photo() && !get_photo_missing());
        
        base.update_ui(missing);
    }
    
    protected override void update_actions(int selected_count, int count) {
        bool multiple = (get_controller() != null) ? get_controller().get_count() > 1 : false;
        bool revert_possible = has_photo() ? get_photo().has_transformations() 
            && !get_photo_missing() : false;
        bool rotate_possible = has_photo() ? is_rotate_available(get_photo()) : false;
        bool enhance_possible = has_photo() ? is_enhance_available(get_photo()) : false;
        
        set_action_sensitive("PrevPhoto", multiple);
        set_action_sensitive("NextPhoto", multiple);
        set_action_sensitive("RotateClockwise", rotate_possible);
        set_action_sensitive("RotateCounterclockwise", rotate_possible);
        set_action_sensitive("FlipHorizontally", rotate_possible);
        set_action_sensitive("FlipVertically", rotate_possible);
        set_action_sensitive("Revert", revert_possible);
        set_action_sensitive("Enhance", enhance_possible);
        
        set_action_sensitive("SetBackground", has_photo());
        
        base.update_actions(selected_count, count);
    }
    
    private bool check_ok_to_close_photo(Photo photo) {
        if (!photo.has_alterations())
            return true;
        
        if (drop_if_dirty) {
            // need to remove transformations, or else they stick around in memory (reappearing
            // if the user opens the file again)
            photo.remove_all_transformations();
            
            return true;
        }

        bool is_writeable = get_photo().get_file_format().can_write();
        string save_option = is_writeable ? _("_Save") : _("_Save a Copy");

        Gtk.ResponseType response = AppWindow.negate_affirm_cancel_question(
            _("Lose changes to %s?").printf(photo.get_name()), save_option,
            _("Close _without Saving"));

        if (response == Gtk.ResponseType.YES)
            photo.remove_all_transformations();
        else if (response == Gtk.ResponseType.NO) {
            if (is_writeable)
                save(photo.get_file(), 0, ScaleConstraint.ORIGINAL, Jpeg.Quality.HIGH,
                    get_photo().get_file_format());
            else
                on_save_as();
        } else if ((response == Gtk.ResponseType.CANCEL) || (response == Gtk.ResponseType.DELETE_EVENT) ||
            (response == Gtk.ResponseType.CLOSE)) {
            return false;
        }

        return true;
    }
    
    public bool check_quit() {
        return check_ok_to_close_photo(get_photo());
    }
    
    protected override bool confirm_replace_photo(Photo? old_photo, Photo new_photo) {
        return (old_photo != null) ? check_ok_to_close_photo(old_photo) : true;
    }
    
    private void save(File dest, int scale, ScaleConstraint constraint, Jpeg.Quality quality,
        PhotoFileFormat format, bool copy_unmodified = false) {
        Scaling scaling = Scaling.for_constraint(constraint, scale, false);
        
        try {
            get_photo().export(dest, scaling, quality, format, copy_unmodified);
        } catch (Error err) {
            AppWindow.error_message(_("Error while saving to %s: %s").printf(dest.get_path(),
                err.message));
            
            return;
        }
        
        // create a new placeholder for the dest, unless one already exists, in which case mark it
        // as requiring a re-import
        DirectPhotoPlaceholder? placeholder = DirectPhotoPlaceholder.global.get_source_for_file(dest);
        if (placeholder != null) {
            placeholder.mark_for_reimport();
        } else {
            placeholder = new DirectPhotoPlaceholder(dest);
            DirectPhotoPlaceholder.global.add(placeholder);
        }
        
        // now fetch the DirectPhoto from the placeholder, which will import it into the database
        // if not already present, or re-import it if it is
        DirectPhoto photo = placeholder.fetch_real_source() as DirectPhoto;
        if (photo is DummyDirectPhoto) {
            // dead in the water
            AppWindow.error_message(_("Unable to load %s: %s").printf(dest.get_path(),
                ((DummyDirectPhoto) photo).get_reason()));
            
            return;
        }
        
        display_mirror_of(view_controller, photo);
    }
    
    private void on_save() {
        if (!get_photo().has_alterations() || !get_photo().get_file_format().can_write() || 
            get_photo_missing())
            return;

        // save full-sized version right on top of the current file
        save(get_photo().get_file(), 0, ScaleConstraint.ORIGINAL, Jpeg.Quality.HIGH,
            get_photo().get_file_format());
    }
    
    private void on_save_as() {
        ExportDialog export_dialog = new ExportDialog(_("Save As"));
        
        int scale;
        ScaleConstraint constraint;
        ExportFormatParameters export_params = ExportFormatParameters.last();
        if (!export_dialog.execute(out scale, out constraint, ref export_params))
            return;

        string filename = get_photo().get_export_basename_for_parameters(export_params);
        PhotoFileFormat effective_export_format =
            get_photo().get_export_format_for_parameters(export_params);

        string[] output_format_extensions =
            effective_export_format.get_properties().get_known_extensions();
        Gtk.FileFilter output_format_filter = new Gtk.FileFilter();
        foreach(string extension in output_format_extensions) {
            string uppercase_extension = extension.up();
            output_format_filter.add_pattern("*." + extension);
            output_format_filter.add_pattern("*." + uppercase_extension);
        }

        Gtk.FileChooserDialog save_as_dialog = new Gtk.FileChooserDialog(_("Save As"), 
            AppWindow.get_instance(), Gtk.FileChooserAction.SAVE, Gtk.STOCK_CANCEL, 
            Gtk.ResponseType.CANCEL, Gtk.STOCK_OK, Gtk.ResponseType.OK);
        save_as_dialog.set_select_multiple(false);
        save_as_dialog.set_current_name(filename);
        save_as_dialog.set_current_folder(current_save_dir.get_path());
        save_as_dialog.add_filter(output_format_filter);
        save_as_dialog.set_do_overwrite_confirmation(true);
        save_as_dialog.set_local_only(false);
        
        int response = save_as_dialog.run();
        if (response == Gtk.ResponseType.OK) {
            // flag to prevent asking user about losing changes to the old file (since they'll be
            // loaded right into the new one)
            drop_if_dirty = true;
            save(File.new_for_uri(save_as_dialog.get_uri()), scale, constraint, export_params.quality,
                effective_export_format, export_params.mode == ExportFormatMode.UNMODIFIED);
            drop_if_dirty = false;

            current_save_dir = File.new_for_path(save_as_dialog.get_current_folder());
        }
        
        save_as_dialog.destroy();
    }
    
    private void on_send_to() {
        if (has_photo())
            DesktopIntegration.send_to((Gee.Collection<Photo>) get_view().get_selected_sources());
    }
    
    protected override bool on_app_key_pressed(Gdk.EventKey event) {
        bool handled = true;
        
        switch (Gdk.keyval_name(event.keyval)) {
            case "bracketright":
                on_rotate_clockwise();
            break;

            case "bracketleft":
                on_rotate_counterclockwise();
            break;

            default:
                handled = false;
            break;
        }
        
        return handled ? true : base.on_app_key_pressed(event);
    }
    
    private void on_print() {
        PrintManager.get_instance().spool_photo((Gee.Collection<MediaSource>) get_view().get_selected_sources());
    }
}

