/*

Boost Software License - Version 1.0 - August 17th, 2003

Permission is hereby granted, free of charge, to any person or organization
obtaining a copy of the software and accompanying documentation covered by
this license (the "Software") to use, reproduce, display, distribute,
execute, and transmit the Software, and to prepare derivative works of the
Software, and to permit third-parties to whom the Software is furnished to
do so, all subject to the following:

The copyright notices in the Software and this entire statement, including
the above license grant, this restriction and the following disclaimer,
must be included in all copies of the Software, in whole or in part, and
all derivative works of the Software, unless such copies or derivative
works are solely in the form of machine-executable object code generated by
a source language processor.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

*/

module derelict.vulkan.system;
public import derelict.vulkan.base;
public import derelict.vulkan.types;
import derelict.util.system;

enum VKSystem {
  Other   = 0,
  Windows = 1 << 0,
  Android = 1 << 1,
  Posix   = 1 << 2
}

mixin SystemFunctionality;

private:
import std.conv;

auto derelictVulkanSystem() {
  static if (Derelict_OS_Posix) {
    return VKSystem.Posix;
  } else static if (Derelict_OS_Windows) {
    return VKSystem.Windows;
  } else static if (Derelict_OS_Android) {
    return VKSystem.Android;
  } else {
    pragma(msg, "Non of currently supported systems is fit to yours. "
              , "If required functionality is missed, feel free to extend and share on GitHub.");
    return VKSystem.Other;
  }
}

mixin template DummyFunctions() {
  pragma(inline, true)
  void bindFunctions(alias bind)() {}
}

mixin template SystemFunctionality() {
  extern(System):
  enum currentSystem = derelictVulkanSystem();
  pragma(msg, "DerelictVulkanSystem: ", to!string(currentSystem));
  static if (currentSystem == VKSystem.Windows) {
    mixin WindowsSys;
  } else static if (currentSystem == VKSystem.Android) {
    mixin AndroidSys;
  } else static if (currentSystem == VKSystem.Posix) {
    mixin PosixSys;
  } else {
    package alias Functions = DummyFunctions;
  }
}

mixin template WindowsSys() {
  import core.sys.windows.windows;
  enum VK_KHR_win32_surface = 1;
  enum VK_KHR_WIN32_SURFACE_SPEC_VERSION   = 5;
  enum VK_KHR_WIN32_SURFACE_EXTENSION_NAME = "VK_KHR_win32_surface";

  alias VkWin32SurfaceCreateFlagsKHR = VkFlags;

  struct VkWin32SurfaceCreateInfoKHR {
    VkStructureType              sType    ;
    const(void)*                 pNext    ;
    VkWin32SurfaceCreateFlagsKHR flags    ;
    HINSTANCE                    hinstance;
    HWND                         hwnd     ;
  }

  alias PFN_vkCreateWin32SurfaceKHR = nothrow 
      VkResult function( VkInstance                          instance
                       , const(VkWin32SurfaceCreateInfoKHR)* pCreateInfo
                       , const(VkAllocationCallbacks)*       pAllocator
                       , VkSurfaceKHR*                       pSurface );
  alias PFN_vkGetPhysicalDeviceWin32PresentationSupportKHR = nothrow 
      VkBool32 function( VkPhysicalDevice physicalDevice, uint queueFamilyIndex );

  mixin template Functions() {
    PFN_vkCreateWin32SurfaceKHR                        vkCreateWin32SurfaceKHR;
		PFN_vkGetPhysicalDeviceWin32PresentationSupportKHR vkGetPhysicalDeviceWin32PresentationSupportKHR;
    pragma(inline, true)
    void bindFunctions(alias bind)() {
      bind(cast(void**)&vkCreateWin32SurfaceKHR, "vkCreateWin32SurfaceKHR");
      bind( cast(void**)&vkGetPhysicalDeviceWin32PresentationSupportKHR
          , "vkGetPhysicalDeviceWin32PresentationSupportKHR");
    }
  }

  version (none) {
    VkResult vkCreateWin32SurfaceKHR( VkInstance                          instance
                                    , const(VkWin32SurfaceCreateInfoKHR)* pCreateInfo
                                    , const(VkAllocationCallbacks)*       pAllocator
                                    , VkSurfaceKHR*                       pSurface );
    VkBool32 vkGetPhysicalDeviceWin32PresentationSupportKHR( VkPhysicalDevice physicalDevice, uint queueFamilyIndex );
  }
}

mixin template AndroidSys() { 
  // #include <android/native_window.h>
  enum VK_KHR_android_surface = 1;
  enum VK_KHR_ANDROID_SURFACE_SPEC_VERSION   = 6;
  enum VK_KHR_ANDROID_SURFACE_EXTENSION_NAME = "VK_KHR_android_surface";

  alias VkAndroidSurfaceCreateFlagsKHR = VkFlags;

  struct VkAndroidSurfaceCreateInfoKHR {
    VkStructureType                sType ;
    const(void)*                   pNext ;
    VkAndroidSurfaceCreateFlagsKHR flags ;
    ANativeWindow*                 window;
  }

  alias PFN_vkCreateAndroidSurfaceKHR = nothrow 
      VkResult function( VkInstance                            instance
                       , const(VkAndroidSurfaceCreateInfoKHR)* pCreateInfo
                       , const(VkAllocationCallbacks)*         pAllocator
                       , VkSurfaceKHR*                         pSurface );
  
  mixin template Functions() {
    PFN_vkCreateAndroidSurfaceKHR vkCreateAndroidSurfaceKHR;
    pragma(inline, true)
    void bindFunctions(alias bind)() {
      bind(cast(void**)&vkCreateAndroidSurfaceKHR, "vkCreateAndroidSurfaceKHR");
    }
  }
  
  version (none) {
    VkResult vkCreateAndroidSurfaceKHR( VkInstance instance
                                      , const(VkAndroidSurfaceCreateInfoKHR)* pCreateInfo
                                      , const(VkAllocationCallbacks)* pAllocator
                                      , VkSurfaceKHR* pSurface);
  }
}

mixin template PosixSys() {
  version (VK_USE_PLATFORM_XCB_KHR)     mixin XCBProtocol    ;
  version (VK_USE_PLATFORM_XLIB_KHR)    mixin XLibProtocol   ;
  version (VK_USE_PLATFORM_MIR_KHR)     mixin MirProtocol    ;
  version (VK_USE_PLATFORM_WAYLAND_KHR) mixin WaylandProtocol;
  else {
    pragma(msg, "Non protocol been selected for Posix system.");
    package alias Functions = DummyFunctions;
  }
}

mixin template XCBProtocol() {
  import xcb.xcb;
  enum VK_KHR_xcb_surface = 1;
  enum VK_KHR_XCB_SURFACE_SPEC_VERSION   = 6;
  enum VK_KHR_XCB_SURFACE_EXTENSION_NAME = "VK_KHR_xcb_surface";

  alias VkXcbSurfaceCreateFlagsKHR = VkFlags;

  struct VkXcbSurfaceCreateInfoKHR {
    VkStructureType            sType     ;
    const(void)*               pNext     ;
    VkXcbSurfaceCreateFlagsKHR flags     ;
    xcb_connection_t*          connection;
    xcb_window_t               window    ;
  }

  alias PFN_vkCreateXcbSurfaceKHR = nothrow 
      VkResult function( VkInstance                        instance
                       , const(VkXcbSurfaceCreateInfoKHR)* pCreateInfo
                       , const(VkAllocationCallbacks)*     pAllocator
                       , VkSurfaceKHR*                     pSurface );
  alias PFN_vkGetPhysicalDeviceXcbPresentationSupportKHR = nothrow 
      VkBool32 function( VkPhysicalDevice  physicalDevice
                       , uint              queueFamilyIndex
                       , xcb_connection_t* connection
                       , xcb_visualid_t    visual_id );

  mixin template Functions() {
    PFN_vkCreateXcbSurfaceKHR                        vkCreateXcbSurfaceKHR;
    PFN_vkGetPhysicalDeviceXcbPresentationSupportKHR vkGetPhysicalDeviceXcbPresentationSupportKHR;
    pragma(inline, true)
    void bindFunctions(alias bind)() {
      bind(cast(void**)&vkCreateXcbSurfaceKHR, "vkCreateXcbSurfaceKHR");
      bind( cast(void**)&vkGetPhysicalDeviceXcbPresentationSupportKHR
          , "vkGetPhysicalDeviceXcbPresentationSupportKHR" );
    }
  }

  version (none) {
    VkResult vkCreateXcbSurfaceKHR( VkInstance                        instance
                                  , const(VkXcbSurfaceCreateInfoKHR)* pCreateInfo
                                  , const(VkAllocationCallbacks)*     pAllocator
                                  , VkSurfaceKHR*                     pSurface );
    VkBool32 vkGetPhysicalDeviceXcbPresentationSupportKHR( VkPhysicalDevice  physicalDevice
                                                         , uint              queueFamilyIndex
                                                         , xcb_connection_t* connection
                                                         , xcb_visualid_t    visual_id);
  }
}

mixin template XLibProtocol() {
  import X11.Xlib;
  enum VK_KHR_xlib_surface = 1;
  enum VK_KHR_XLIB_SURFACE_SPEC_VERSION   = 6;
  enum VK_KHR_XLIB_SURFACE_EXTENSION_NAME = "VK_KHR_xlib_surface";

  alias VkXlibSurfaceCreateFlagsKHR = VkFlags;

  struct VkXlibSurfaceCreateInfoKHR {
    VkStructureType             sType ;
    const(void)*                pNext ;
    VkXlibSurfaceCreateFlagsKHR flags ;
    Display*                    dpy   ;
    Window                      window;
  }

  alias PFN_vkCreateXlibSurfaceKHR = nothrow 
      VkResult function( VkInstance                         instance
                       , const(VkXlibSurfaceCreateInfoKHR)* pCreateInfo
                       , const(VkAllocationCallbacks)*      pAllocator
                       , VkSurfaceKHR*                      pSurface );
  alias PFN_vkGetPhysicalDeviceXlibPresentationSupportKHR = nothrow 
      VkBool32 function( VkPhysicalDevice physicalDevice
                       , uint             queueFamilyIndex
                       , Display*         dpy
                       , VisualID         visualID);

  mixin template Functions() {
    PFN_vkCreateXlibSurfaceKHR                        vkCreateXlibSurfaceKHR;
    PFN_vkGetPhysicalDeviceXlibPresentationSupportKHR vkGetPhysicalDeviceXlibPresentationSupportKHR;
    pragma(inline, true)
    void bindFunctions(alias bind)() {
      bind(cast(void**)&vkCreateXlibSurfaceKHR, "vkCreateXlibSurfaceKHR");
      bind( cast(void**)&vkGetPhysicalDeviceXlibPresentationSupportKHR
          , "vkGetPhysicalDeviceXlibPresentationSupportKHR" );
    }
  }

  version (none) {
    VkResult vkCreateXlibSurfaceKHR( VkInstance                         instance
                                   , const(VkXlibSurfaceCreateInfoKHR)* pCreateInfo
                                   , const(VkAllocationCallbacks)*      pAllocator
                                   , VkSurfaceKHR*                      pSurface );
    VkBool32 vkGetPhysicalDeviceXlibPresentationSupportKHR( VkPhysicalDevice physicalDevice
                                                          , uint queueFamilyIndex
                                                          , Display* dpy
                                                          , VisualID visualID );
  }
}

mixin template MirProtocol() {
  //TODO: add import of data related to Mir protocol
  // #include <mir_toolkit/client_types.h>
  enum VK_KHR_mir_surface = 1;
  enum VK_KHR_MIR_SURFACE_SPEC_VERSION   = 4;
  enum VK_KHR_MIR_SURFACE_EXTENSION_NAME = "VK_KHR_mir_surface";

  alias VkMirSurfaceCreateFlagsKHR = VkFlags;

  struct VkMirSurfaceCreateInfoKHR {
    VkStructureType            sType     ;
    const(void)*               pNext     ;
    VkMirSurfaceCreateFlagsKHR flags     ;
    MirConnection*             connection;
    MirSurface*                mirSurface;
  }

  alias PFN_vkCreateMirSurfaceKHR = nothrow 
      VkResult function( VkInstance                        instance
                       , const(VkMirSurfaceCreateInfoKHR)* pCreateInfo
                       , const(VkAllocationCallbacks)*     pAllocator
                       , VkSurfaceKHR*                     pSurface );
  alias PFN_vkGetPhysicalDeviceMirPresentationSupportKHR = nothrow 
      VkBool32 function( VkPhysicalDevice physicalDevice
                       , uint queueFamilyIndex
                       , MirConnection* connection);

  mixin template Functions() {
    PFN_vkCreateMirSurfaceKHR                        vkCreateMirSurfaceKHR;
    PFN_vkGetPhysicalDeviceMirPresentationSupportKHR vkGetPhysicalDeviceMirPresentationSupportKHR;
    pragma(inline, true)
    void bindFunctions(alias bind)() {
      bind(cast(void**)&vkCreateMirSurfaceKHR, "vkCreateMirSurfaceKHR");
      bind( cast(void**)&vkGetPhysicalDeviceMirPresentationSupportKHR
          , "vkGetPhysicalDeviceMirPresentationSupportKHR");
    }
  }

  version (none) {
    VkResult vkCreateMirSurfaceKHR( VkInstance                        instance
                                  , const(VkMirSurfaceCreateInfoKHR)* pCreateInfo
                                  , const(VkAllocationCallbacks)*     pAllocator
                                  , VkSurfaceKHR*                     pSurface );
    VkBool32 vkGetPhysicalDeviceMirPresentationSupportKHR( VkPhysicalDevice physicalDevice
                                                         , uint             queueFamilyIndex
                                                         , MirConnection*   connection );
  }
}

mixin template WaylandProtocol() {
  //TODO: add import of data related to Wayland protocol
  // #include <wayland-client.h>
  enum VK_KHR_wayland_surface = 1;
  enum VK_KHR_WAYLAND_SURFACE_SPEC_VERSION   = 5;
  enum VK_KHR_WAYLAND_SURFACE_EXTENSION_NAME = "VK_KHR_wayland_surface";

  alias VkWaylandSurfaceCreateFlagsKHR = VkFlags;

  struct VkWaylandSurfaceCreateInfoKHR {
    VkStructureType                sType  ;
    const(void)*                   pNext  ;
    VkWaylandSurfaceCreateFlagsKHR flags  ;
    wl_display*                    display;
    wl_surface*                    surface;
  }

  alias PFN_vkCreateWaylandSurfaceKHR = nothrow 
      VkResult function( VkInstance                            instance
                       , const(VkWaylandSurfaceCreateInfoKHR)* pCreateInfo
                       , const(VkAllocationCallbacks)*         pAllocator
                       , VkSurfaceKHR*                         pSurface );
  alias PFN_vkGetPhysicalDeviceWaylandPresentationSupportKHR = nothrow 
      VkBool32 function( VkPhysicalDevice physicalDevice
                       , uint             queueFamilyIndex
                       , wl_display*      display );

  mixin template Functions() {
    PFN_vkCreateWaylandSurfaceKHR                        vkCreateWaylandSurfaceKHR;
    PFN_vkGetPhysicalDeviceWaylandPresentationSupportKHR vkGetPhysicalDeviceWaylandPresentationSupportKHR;
    pragma(inline, true)
    void bindFunctions(alias bind)() {
      bind(cast(void**)&vkCreateWaylandSurfaceKHR, "vkCreateWaylandSurfaceKHR");
      bind( cast(void**)&vkGetPhysicalDeviceWaylandPresentationSupportKHR
          , "vkGetPhysicalDeviceWaylandPresentationSupportKHR" );
    }
  }

  version (none) {
    VkResult vkCreateWaylandSurfaceKHR( VkInstance                            instance
                                      , const(VkWaylandSurfaceCreateInfoKHR)* pCreateInfo
                                      , const(VkAllocationCallbacks)*         pAllocator
                                      , VkSurfaceKHR*                         pSurface );
    VkBool32 vkGetPhysicalDeviceWaylandPresentationSupportKHR( VkPhysicalDevice physicalDevice
                                                             , uint             queueFamilyIndex
                                                             , wl_display*      display );
  }
}