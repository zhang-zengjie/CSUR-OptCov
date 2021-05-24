function [outList, adjacentList] = ComputeVoronoiProperty(trueCoord, CVTCoord, verList, verPtr)
    n = numel(verPtr);
    outList = zeros(n, n, 5); % Checkflag - dCix/dzjx - dCix/dzjy - dCiy/dzjx - dCiy/dzjy 
    [adjacentList] = computeAdjacentList(CVTCoord, verList, verPtr);
    if(1)
        global cellColors;
        cellColors = summer(n);
        [ax] = Plot_Cell(trueCoord, CVTCoord, verList, verPtr);
    end
    % CVTCoord      : CVT information of each agent
    % adjacentList  : 
    for thisCell = 1:n
        thisCVT = CVTCoord(thisCell, :);
        verThisCell = verPtr{thisCell}(1:end-1);
        coordVertexX = verList(verThisCell,1);
        coordVertexY = verList(verThisCell,2);
        [mOmegai, denseXi, denseYi] = computePartitionMass(coordVertexX, coordVertexY);
        
        % Take the information of this cell's adjacent to compute the
        % derivative
        flagAdj =  adjacentList(thisCell,:,1);
        thisAdjList = find(flagAdj);
        ownParitialDerivative = zeros(2,2);
        for i = 1: numel(thisAdjList)
            adjIndex = thisAdjList(i);
            curAdjCoord = CVTCoord(adjIndex, :);
            commonVertex1 = [adjacentList(thisCell, adjIndex, 6), adjacentList(thisCell, adjIndex, 7)];
            commonVertex2 = [adjacentList(thisCell, adjIndex, 8), adjacentList(thisCell, adjIndex, 9)];
            % Debugging
            %if(1)
            %    plot([commonVertex1(1) commonVertex2(1)] , [commonVertex1(2) commonVertex2(2)], 'Color', cellColors(thisCell,:));
            %end
            [tmpdCidZi, adjacentPartialDerivative] = ComputePartialDerivativeCVT(thisCVT, curAdjCoord, commonVertex1, commonVertex2, mOmegai, denseXi, denseYi);
            ownParitialDerivative = ownParitialDerivative + tmpdCidZi;
            % Update the desired information
            outList(thisCell, adjIndex, 1) = true; % Is neighbor ?
            outList(thisCell, adjIndex, 2) = adjacentPartialDerivative(1, 1);    % adjacentPartialDerivative dCix_dzjx
            outList(thisCell, adjIndex, 3) = adjacentPartialDerivative(1, 2);    % adjacentPartialDerivative dCix_dzjy
            outList(thisCell, adjIndex, 4) = adjacentPartialDerivative(2, 1);    % adjacentPartialDerivative dCiy_dzjx
            outList(thisCell, adjIndex, 5) = adjacentPartialDerivative(2, 2);    % adjacentPartialDerivative dCiy_dzjy
        end
        outList(thisCell, thisCell, 2) = ownParitialDerivative(1, 1);    % adjacentPartialDerivative dCix_dzix
        outList(thisCell, thisCell, 3) = ownParitialDerivative(1, 2);    % adjacentPartialDerivative dCix_dziy
        outList(thisCell, thisCell, 4) = ownParitialDerivative(2, 1);    % adjacentPartialDerivative dCiy_dzix
        outList(thisCell, thisCell, 5) = ownParitialDerivative(2, 2);    % adjacentPartialDerivative dCiy_dziy
    end    
end

%% Compute the mass of Voronoi partition
function [mOmega, denseX, denseY] = computePartitionMass(coordVertexX, coordVertexY)
        IntDomain = struct('type','polygon','x',coordVertexX(:)','y',coordVertexY(:)');
        param = struct('method','gauss','points',6); 
        %param = struct('method','dblquad','tol',1e-6);
        %% The total mass of the region
        func = @(x,y) x*y;
        mOmega = doubleintegral(func, IntDomain, param);
        
        %% The density over X axis
        denseFuncX = @(x,y) x;
        denseX = doubleintegral(denseFuncX, IntDomain, param);
        
        %% The density over Y axis
        denseFuncY = @(x,y) y;
        denseY = doubleintegral(denseFuncY, IntDomain, param);
end

%% Compute the partial derivative of CVTs to adjacent CVT
function [dCi_dzi_AdjacentJ, dCi_dzj] = ComputePartialDerivativeCVT(thisPos, thatPos, vertex1, vertex2, mVi, denseViX, denseViY)
    %% Function definition for partial derivative
    rho = @(x,y) x;
    gradZjOfQ = @(q, zjXorY, ziXorY) ((zjXorY - ziXorY)/2 - (q - (ziXorY + zjXorY)/2)); 
    gradZiOfQ = @(q, zjXorY, ziXorY) ((zjXorY - ziXorY)/2 + (q - (ziXorY + zjXorY)/2)); 

    dCix_dzjx_func      = @(t, a, b, zjx, zix) rho(t,a*t+b) .* (t              .* gradZjOfQ(t, zjx, zix)             .* (1 + a^2)^(1/2));
    dCix_dzjy_func      = @(t, a, b, zjy, ziy) rho(t,a*t+b) .* (t              .* gradZjOfQ((a * t + b), zjy, ziy)   .* (1 + a^2)^(1/2));
    dCiy_dzjx_func      = @(t, a, b, zjx, zix) rho(t,a*t+b) .* ((a * t + b)    .* gradZjOfQ(t, zjx, zix)             .* (1 + a^2)^(1/2));
    dCiy_dzjy_func      = @(t, a, b, zjy, ziy) rho(t,a*t+b) .* ((a * t + b)    .* gradZjOfQ((a * t + b), zjy, ziy)   .* (1 + a^2)^(1/2));
    gradZjOfQ_intFunc   = @(t, a, b, zj, zi)   rho(t,a*t+b) .* ((zj - zi)/2 - (t - (zj + zi)/2)) * (1 + a^2)^(1/2); 
    
    dCix_dzix_func      = @(t, a, b, zjx, zix) rho(t,a*t+b) .* (t              .* gradZiOfQ(t, zjx, zix)             .* (1 + a^2)^(1/2)) ;
    dCix_dziy_func      = @(t, a, b, zjy, ziy) rho(t,a*t+b) .* (t              .* gradZiOfQ((a * t + b), zjy, ziy)   .* (1 + a^2)^(1/2));
    dCiy_dzix_func      = @(t, a, b, zjx, zix) rho(t,a*t+b) .* ((a * t + b)    .* gradZiOfQ(t, zjx, zix)             .* (1 + a^2)^(1/2));
    dCiy_dziy_func      = @(t, a, b, zjy, ziy) rho(t,a*t+b) .* ((a * t + b)    .* gradZiOfQ((a * t + b), zjy, ziy)   .* (1 + a^2)^(1/2));
    gradZiOfQ_intFunc   = @(t, a, b, zj, zi)   rho(t,a*t+b) .* ((zj - zi)/2 + (t - (zj + zi)/2)) .* (1 + a^2)^(1/2); 

    % Name convention
    zix = thisPos(1);
    ziy = thisPos(2);
    zjx = thatPos(1);
    zjy = thatPos(2);

    % Temporary save the vertexes of the adjacent boundary. Boundary line is
    % defined by 2 points, we use the "start" and "end" notation for the
    % integration
    x1     = vertex1(1);
    y1     = vertex1(2);
    
    x2       = vertex2(1);
    y2       = vertex2(2);
    % 2 cases to determine the line y = ax + b
    dsIsdy = 0;
    if(x1 ~= x2)
       a = (y2 - y1) / (x2 - x1); 
       b = y1 - a * x1;
    else       
       dsIsdy = 1;
    end

    % Distance to the neighbor agent
    dZiZj = norm(thisPos - thatPos);

    % Partial derivative computation
    dCix_dzjx = (integral(@(x) dCix_dzjx_func(x,a,b,zjx,zix), x1, x2) / mVi  -  integral(@(x)gradZjOfQ_intFunc(x    ,a,b,zjx,zix), x1, x2) * denseViX / mVi ^ 2) / dZiZj;
    dCix_dzjy = (integral(@(x) dCix_dzjy_func(x,a,b,zjy,ziy), x1, x2) / mVi  -  integral(@(x)gradZjOfQ_intFunc(a*x+b,a,b,zjy,ziy), x1, x2) * denseViY / mVi ^ 2) / dZiZj;
    dCiy_dzjx = (integral(@(x) dCiy_dzjx_func(x,a,b,zjx,zix), x1, x2) / mVi  -  integral(@(x)gradZjOfQ_intFunc(x    ,a,b,zjx,zix), x1, x2) * denseViX / mVi ^ 2) / dZiZj;
    dCiy_dzjy = (integral(@(x) dCiy_dzjy_func(x,a,b,zjy,ziy), x1, x2) / mVi  -  integral(@(x)gradZjOfQ_intFunc(a*x+b,a,b,zjy,ziy), x1, x2) * denseViY / mVi ^ 2) / dZiZj;

    dCix_dzix = (integral(@(x) dCix_dzix_func(x,a,b,zjx,zix), x1, x2) / mVi  -  integral(@(x)gradZiOfQ_intFunc(x    ,a,b,zjx,zix), x1, x2) * denseViX / mVi ^ 2) / dZiZj;
    dCix_dziy = (integral(@(x) dCix_dziy_func(x,a,b,zjy,ziy), x1, x2) / mVi  -  integral(@(x)gradZiOfQ_intFunc(a*x+b,a,b,zjy,ziy), x1, x2) * denseViY / mVi ^ 2) / dZiZj;
    dCiy_dzix = (integral(@(x) dCiy_dzix_func(x,a,b,zjx,zix), x1, x2) / mVi  -  integral(@(x)gradZiOfQ_intFunc(x    ,a,b,zjx,zix), x1, x2) * denseViX / mVi ^ 2) / dZiZj;
    dCiy_dziy = (integral(@(x) dCiy_dziy_func(x,a,b,zjy,ziy), x1, x2) / mVi  -  integral(@(x)gradZiOfQ_intFunc(a*x+b,a,b,zjy,ziy), x1, x2) * denseViY / mVi ^ 2) / dZiZj; 

    dCi_dzi_AdjacentJ   = [dCix_dzix, dCix_dziy; dCiy_dzix, dCiy_dziy];
    dCi_dzj             = [dCix_dzjx, dCix_dzjy; dCiy_dzjx, dCiy_dzjy];
end

%% Determine which CVTs are adjacent CVTs
function [adjacentList] = computeAdjacentList(centroidPos, vertexes, vertexHandler)
    % Check for all agent
    nCell = numel(vertexHandler);
    % Return the result [adjacentList] with the following information - 9 columns 
    % CheckNeighborflag - [thisCVT: x y] - [neighborCVT: x y] - [vertex1: x y] - [vertex2: x y]
    adjacentList = zeros(nCell,nCell, 9);  
    %% Start searching for common vertexes to determine neighbor agents
    for thisCVT = 1 : nCell
        thisVertexList = vertexHandler{thisCVT}(1:end - 1);
        % Checking all another CVTs
        for nextCVT = 1: nCell
              if(nextCVT ~= thisCVT)
                    cnt = 0;
                    nextVertexList = vertexHandler{nextCVT}(1:end-1); 
                       % Comparing these 2 arrays to find out whether it is the
                       % adjacent CVT or not  -> currentVertexes vs vertexBeingChecked
                       isNeighbor = false;
                       for l = 1 : numel(thisVertexList)
                          for k = 1 : numel(nextVertexList)
                             % Some work around flag here because small
                             % values can not be exactly compared
                             tol = 0.000001;
                             workaroundFlag = (abs(vertexes(thisVertexList(l),1) - vertexes(nextVertexList(k),1)) < tol) && (abs(vertexes(thisVertexList(l),2) - vertexes(nextVertexList(k),2)) < tol); % Observe identical vertexes -> work around with this condition
                             if ((thisVertexList(l) == nextVertexList(k)) || workaroundFlag(1))   
                                % Once this part is triggered, the coord under comparision is the adjacent coord
                                isNeighbor = true;
                                adjacentList(thisCVT, nextCVT, 1) = true;
                                % The Coord of this CVT
                                adjacentList(thisCVT, nextCVT, 2) = centroidPos(thisCVT,1);   % X
                                adjacentList(thisCVT, nextCVT, 3) = centroidPos(thisCVT,2);   % Y
                                % Put Neighbor CVT's Coord here
                                adjacentList(thisCVT, nextCVT, 4) = centroidPos(nextCVT,1);   % X
                                adjacentList(thisCVT, nextCVT, 5) = centroidPos(nextCVT,2);   % Y
                                % Counter to control the number of vertexes
                                % Update the vertexes into the output
                                % array. We control the amount of vertexes
                                % for precise line integration
                                cnt = cnt + 1;
                                if cnt == 1
                                    adjacentList(thisCVT, nextCVT, 6) = vertexes(thisVertexList(l),1); % First vertex
                                    adjacentList(thisCVT, nextCVT, 7) = vertexes(thisVertexList(l),2); % First vertex
                                elseif cnt == 2
                                    adjacentList(thisCVT, nextCVT, 8) = vertexes(thisVertexList(l),1); % Second vertex
                                    adjacentList(thisCVT, nextCVT, 9) = vertexes(thisVertexList(l),2); % Second vertex  
                                elseif cnt >= 3
                                    error("More than 3 vertexes for 1 common line detected");
                                end
                             end
                          end
                       end
                  if(isNeighbor == false)
                      adjacentList(thisCVT, nextCVT, 1) = false;
                      adjacentList(thisCVT, nextCVT, 2:end) = 0;
                  elseif cnt == 1
                         % adjacent agent with only 1 vertex does not
                         % effect the integration so we can skip it
                         adjacentList(thisCVT, nextCVT, 1) = false;
                         adjacentList(thisCVT, nextCVT, 2:end) = 0;
                         
                         %adjacentList(thisCVT, nextCVT, 8) = adjacentList(thisCVT, nextCVT, 6); % Second vertex is same as the first common vertex
                         %adjacentList(thisCVT, nextCVT, 9) = adjacentList(thisCVT, nextCVT, 7); 
%                        while 1
%                           disp("Not enough vertexes");
%                        end
                  end
              end
         end
    end
end