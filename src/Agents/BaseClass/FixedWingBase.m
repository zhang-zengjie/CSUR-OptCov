classdef FixedWingBase < handle & AgentBase
    %FixedWingBase Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        AgentPose_3d = zeros(3,1);
        VMCoord_2d = zeros(2,1);
        
        v = 0.0
        w = 0.0
        controlParam
        
        prev_AgentPose_3d
        prev_VMCoord_2d
    end
    
    methods
        function obj = FixedWingBase(dt, id, controlParam, startPose)
            obj@AgentBase(dt, id);
            obj.ID = id;
            obj.controlParam = controlParam;
            obj.AgentPose_3d = startPose;
            
            %% Update initial position and the virtual center
            obj.AgentPose_3d(:) = startPose(:);
            obj.VMCoord_2d(1) = obj.AgentPose_3d(1) - (obj.controlParam.V_CONST(obj.ID)/obj.controlParam.W_ORBIT(obj.ID)) * sin(obj.AgentPose_3d(3)); 
            obj.VMCoord_2d(2) = obj.AgentPose_3d(2) + (obj.controlParam.V_CONST(obj.ID)/obj.controlParam.W_ORBIT(obj.ID)) * cos(obj.AgentPose_3d(3)); 
        end

        %% Simulate dynamic model 
        function obj = move(obj, v, w) 
            obj.v = v;
            obj.w = w;
            % Unicycle Dynamic
            obj.prev_AgentPose_3d = obj.AgentPose_3d;
            obj.AgentPose_3d(1) = obj.AgentPose_3d(1) + obj.dt * (obj.v * cos(obj.AgentPose_3d(3)));
            obj.AgentPose_3d(2) = obj.AgentPose_3d(2) + obj.dt * (obj.v * sin(obj.AgentPose_3d(3)));
            obj.AgentPose_3d(3) = obj.AgentPose_3d(3) + obj.dt * obj.w;
            %% Update the virtual mass
            obj.prev_VMCoord_2d = obj.VMCoord_2d;
            obj.VMCoord_2d(1) = obj.AgentPose_3d(1) - (obj.v/obj.controlParam.W_ORBIT(obj.ID)) * sin(obj.AgentPose_3d(3)); 
            obj.VMCoord_2d(2) = obj.AgentPose_3d(2) + (obj.v/obj.controlParam.W_ORBIT(obj.ID)) * cos(obj.AgentPose_3d(3)); 
        end
        
        function [Pose_3d] = get_pose(obj)
            Pose_3d =  obj.AgentPose_3d;
        end
 
        function [Coord_3] = get_coord_3(obj)
            % Todo: properly distinguish coord and pose (orientation)
            Coord_3 = [obj.AgentPose_3d(1:2), 0];
        end

    end
end

