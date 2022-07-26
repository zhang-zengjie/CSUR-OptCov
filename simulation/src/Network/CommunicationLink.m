%%

classdef CommunicationLink < handle
    properties (Access = private)
        %% Help variables
        ID_List
        
        %% Communication
        nAgent
        NeighborReportTable   
    end
    
    methods
        function obj = CommunicationLink(nAgents, ID_List)
            obj.nAgent = nAgents;
            obj.ID_List = ID_List;
            obj.NeighborReportTable = cell(nAgents, 1);
            for i = 1 : nAgents
                obj.NeighborReportTable{i} = cell(obj.nAgent, 1);
            end
            obj.ID_List = ID_List;          
        end

        function uploadVoronoiPartialDerivativeProperty(obj, UploaderID, report)
            assert(isa(report, 'Struct_Neighbor_CVT_PD'));
            txAgentIndex = find(obj.ID_List  == UploaderID);
            assert(~isempty(txAgentIndex)); %% Agent not yet registered in the communication link so it can not upload

            % Delete the previously transmitted data (In practice, this should be checked by the timestamp)
            obj.NeighborReportTable{txAgentIndex} = cell(obj.nAgent, 1);
            for i = 1: numel(report)
                [txId, rxID] = report(i).getIDs();
                rxAgentIndex = find(obj.ID_List  == rxID, 1);
                assert(~isempty(rxAgentIndex)); %% Receiver Agent not yet registered in the communication link so it can not upload
                obj.NeighborReportTable{txAgentIndex}{rxAgentIndex} = report(i);
            end
        end
        
        function [out, isAvailable] = downloadVoronoiPartialDerivativeProperty(obj, agentID)
            requestAgentIndex = find(obj.ID_List == agentID);
            out = cell(obj.nAgent, 1);
            isAvailable = false;
            for i = 1: obj.nAgent
                if(~isempty(obj.NeighborReportTable{i}{requestAgentIndex}))
                    out{i} = obj.NeighborReportTable{i}{requestAgentIndex};
                    isAvailable = true;
                end
            end
            if(isAvailable)
                out = out(~cellfun(@isempty,out));
            else
                fprintf("Data sharing for Agent %d is not available \n", agentID);
            end
        end
        
    end
end

