module ProMotion
  module ScreenNavigation
    def open_screen(screen, args = {})
      # Instantiate screen if given a class instead
      screen = screen.new if screen.respond_to? :new
      screen.add_nav_bar if args[:nav_bar]
      screen.parent_screen = self

      screen.main_controller.hidesBottomBarWhenPushed = args[:hide_tab_bar] if args[:hide_tab_bar]
      
      if args[:close_all]
        fresh_start(screen)
      elsif args[:modal]
        screen.modal = true
        self.view_controller.presentModalViewController(screen.main_controller, animated:true)
      elsif self.navigation_controller
        screen.navigation_controller = self.navigation_controller
        push_view_controller screen.view_controller
      else
        open_view_controller screen.main_controller
      end
      
      screen.send(:on_opened) if screen.respond_to?(:on_opened)
    end

    def fresh_start(screen)
      app_delegate.fresh_start(screen)
    end

    def app_delegate
      UIApplication.sharedApplication.delegate
    end

    def close_screen(args = {})
      # Pop current view, maybe with arguments, if in navigation controller
      if self.is_modal?
        self.parent_screen.view_controller.dismissModalViewControllerAnimated(true)
      elsif self.navigation_controller
        self.navigation_controller.popViewControllerAnimated(true)
      else
        # What do we do now? Nothing to "pop". For now, don't do anything.
      end
      
      self.parent_screen.send(:on_return, args) if self.parent_screen && self.parent_screen.respond_to?(:on_return)
    end

    def tab_bar_controller(*screens)
      tab_bar_controller = UITabBarController.alloc.init

      view_controllers = []
      screens.each do |s|
        if s.is_a? Screen
          s = s.new if s.respond_to? :new
          view_controllers << s.main_controller
        else
          Console.log("Non-Screen passed into tab_bar_controller: #{s.to_s}", withColor: Console::RED_COLOR)
        end
      end

      tab_bar_controller.viewControllers = view_controllers
      tab_bar_controller
    end
    
    def open_tab_bar(*screens)
      tab_bar = tab_bar_controller(*screens)
      open_view_controller tab_bar
      screens.each do |s|
        s.on_opened if s.respond_to? :on_opened
        s.parent_screen = self if s.respond_to? "parent_screen="
      end
      tab_bar
    end

    def push_tab_bar(*screens)
      tab_bar = tab_bar_controller(*screens)
      push_view_controller tab_bar
      screens.each do |s|
        s.on_opened if s.respond_to? :on_opened
        s.parent_screen = self if s.respond_to? "parent_screen="
      end
      tab_bar
    end

    def open_view_controller(vc)
      UIApplication.sharedApplication.delegate.load_root_view vc
    end

    def push_view_controller(vc)
      # vc.hidesBottomBarWhenPushed = true if args[:hide_tab_bar]
      Console.log(" You need a nav_bar if you are going to push #{vc.to_s} onto it.", withColor: Console::RED_COLOR) unless self.navigation_controller
      self.navigation_controller.pushViewController(vc, animated: true)
    end
  end
end