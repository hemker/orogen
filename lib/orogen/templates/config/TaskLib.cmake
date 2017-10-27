# What does the task library needs ?
#  - it needs to be able to include the <typekit_name>TypekitTypes.hpp files for
#    each used typekit. It does not need to link the library, though, because the
#    typekit itself is hidden from the actual task contexts.
#  - it needs to have access to the dependent task libraries and libraries. This
#    is true for both the headers and the link interface itself.
#
# What this file does is set up the following variables:
#  component_TASKLIB_NAME
#     the name of the library (test-tasks-gnulinux for instance)
#
#  <PROJECT>_TASKLIB_SOURCES
#     the .cpp files that define the task context classes, including the
#     autogenerated parts.
#
#  <PROJECT>_TASKLIB_SOURCES
#     the .hpp files that declare the task context classes, including the
#     autogenerated parts.
#
#  <PROJECT>_TASKLIB_DEPENDENT_LIBRARIES
#     the list of libraries to which the task library should be linked.
#
#  <PROJECT>_TASKLIB_INTERFACE_LIBRARIES
#     the list of libraries to which users of the task library should be linked
#     as well
#
# These variables are used in tasks/CMakeLists.txt to actually build the shared
# object.

include_directories(${CMAKE_CURRENT_SOURCE_DIR})

<% if project.typekit %>
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/typekit)
list(APPEND <%= project.name.upcase %>_TASKLIB_DEPENDENT_LIBRARIES 
    <%= project.name %>-typekit-${OROCOS_TARGET})
<% end %>

<% fake_install_dir = File.join(AUTOMATIC_AREA_NAME, "__include_tree__", project.name)
   project.self_tasks.each do |task|
     basepath = task.basepath
     basename = task.basename
     symlink_target_path = File.join(fake_install_dir, basepath)
     symlink_source_path = File.join('tasks', basepath) %>
orogen_create_symlink(
    "${PROJECT_BINARY_DIR}/<%= symlink_target_path %>/<%= task.basename %>.hpp"
    "${PROJECT_SOURCE_DIR}/<%= symlink_source_path %>/<%= task.basename %>.hpp")
orogen_create_symlink(
    "${PROJECT_BINARY_DIR}/<%= symlink_target_path %>/<%= task.basename %>Base.hpp"
    "${PROJECT_SOURCE_DIR}/<%= AUTOMATIC_AREA_NAME %>/<%= symlink_source_path %>/<%= task.basename %>Base.hpp")
<% end %>

<% dependencies = project.tasklib_dependencies %>
<%= Generation.cmake_pkgconfig_require(dependencies) %>
<% dependencies.each do |dep_def|
     next if !dep_def.in_context?('link') %>
list(APPEND <%= project.name.upcase %>_TASKLIB_DEPENDENT_LIBRARIES ${<%= dep_def.var_name %>_LIBRARIES})
<%   if dep_def.var_name =~ /TASKLIB/ %>
list(APPEND <%= project.name.upcase %>_TASKLIB_INTERFACE_LIBRARIES ${<%= dep_def.var_name %>_LIBRARIES})
<%   end
   end %>

CONFIGURE_FILE(${PROJECT_SOURCE_DIR}/<%= Generation::AUTOMATIC_AREA_NAME %>/tasks/<%= project.name %>-tasks.pc.in
    ${CMAKE_CURRENT_BINARY_DIR}/<%= project.name %>-tasks-${OROCOS_TARGET}.pc @ONLY)
INSTALL(FILES ${CMAKE_CURRENT_BINARY_DIR}/<%= project.name %>-tasks-${OROCOS_TARGET}.pc
    DESTINATION lib/pkgconfig)

<% include_files = []
   task_files = []
   project.self_tasks.each do |task| 
     if !task_files.empty?
	 task_files << "\n    "
     end
     task_files << "${CMAKE_CURRENT_SOURCE_DIR}/../#{Generation::AUTOMATIC_AREA_NAME}/tasks/#{task.basepath}/#{task.basename}Base.cpp"
     task_files << "#{task.basepath}#{task.basename}.cpp"
     include_files << "${CMAKE_CURRENT_SOURCE_DIR}/../#{Generation::AUTOMATIC_AREA_NAME}/tasks/#{task.basepath}/#{task.basename}Base.hpp"
     include_files << "#{task.basepath}#{task.basename}.hpp"
   end %>

add_definitions(-DRTT_COMPONENT)
set(<%= project.name.upcase %>_TASKLIB_NAME <%= project.name %>-tasks-${OROCOS_TARGET})
set(<%= project.name.upcase %>_TASKLIB_SOURCES
    ${PROJECT_SOURCE_DIR}/<%= Generation::AUTOMATIC_AREA_NAME %>/tasks/DeployerComponent.cpp
    <%= task_files.sort.join(";") %>)
set(<%= project.name.upcase %>_TASKLIB_HEADERS <%= include_files.sort.join(";") %>)
include_directories(${OrocosRTT_INCLUDE_DIRS})
link_directories(${OrocosRTT_LIBRARY_DIRS})
add_definitions(${OrocosRTT_CFLAGS_OTHER})

