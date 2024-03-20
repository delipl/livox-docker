ARG ROS_DISTRO=humble
ARG PREFIX=

FROM husarnet/ros:humble-ros-core
SHELL ["/bin/bash", "-c"]
WORKDIR /ros2_ws

RUN apt update && apt install -y \
        git \ 
        build-essential \
        python3-rosdep \ 
        python3-colcon-common-extensions \
        libpcl-dev \
        libapr1-dev \
        && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


RUN git clone https://github.com/Livox-SDK/Livox-SDK2.git && \
    cd ./Livox-SDK2/ && \
    mkdir build && \
    cd build && \
    cmake .. && make -j && \
    make install && \
    rm -rf /ros2_ws/Livox-SDK2

RUN git clone https://github.com/Livox-SDK/livox_ros_driver2.git /ros2_ws/src/livox_ros_driver2 && \
    cp /ros2_ws/src/livox_ros_driver2/package_ROS2.xml /ros2_ws/src/livox_ros_driver2/package.xml

RUN MYDISTRO=${PREFIX:-ros}; MYDISTRO=${MYDISTRO//-/} && \
    apt update && \
    source "/opt/$MYDISTRO/$ROS_DISTRO/setup.bash" && \
    # without this line (using vulcanexus base image) rosdep init throws error: "ERROR: default sources list file already exists:"
    rm -rf /etc/ros/rosdep/sources.list.d/20-default.list && \
    rosdep init && \
    rosdep update --rosdistro $ROS_DISTRO && \
    rosdep install -i --from-path src --rosdistro $ROS_DISTRO -y && \
    cd /ros2_ws/src/livox_ros_driver2/ && ./build.sh humble && \
    rm -rf /var/lib/apt/lists/*

RUN echo $(cat /ros2_ws/src/livox_ros_driver2/package.xml | grep '<version>' | sed -r 's/.*<version>([0-9]+.[0-9]+.[0-9]+)<\/version>/\1/g') > /version.txt
