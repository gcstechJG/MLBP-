function [abp, features, pass] = featuresFromABPCycle(wvobj, abp, DEBUG)
%%Function to extract features from a single abp cycle. Return features in
% featuress and pass flag indication if the abp passes the two Gaussian fitting
% criteria
    %DEBUG = true;

    wvobj.deTrend(abp, true);
    wvobj.setWave(wvobj.m_Wave, 'normalize');
    [features,pass] = wvobj.qualifyCycles(wvobj.m_SamplingFrequency, 2);
    if(pass)
        abp = wvobj.m_Wave;
    end
    

    if(DEBUG)
        if(pass == 1)
            figure(10001);
            hold on;
            grid on;
            fitStr = ['Model error = ', num2str(wvobj.m_ModelError)];
            plotmulti(3, abp, wvobj.m_Wave, wvobj.m_ModelFitted, ['Raw abp Signal, PASS with ' fitStr], 'obj.m_Wave (Normalized)', ...
                'obj.m_ModelFitted (Gaussian)');
        else
            figure(10002);
            switch(pass)
                case 0
                    errMsg = 'Fit failed: Model error';
                case -1
                    errMsg = 'Fit failed: Frontend Lift';
                case -2
                    errMsg = 'Fit failed: backend Lift';
                otherwise
                    errMsg = 'Fit failed: for what ever reason.';
            end
            hold on;
            grid on;
            plotmulti(3, abp,  wvobj.m_Wave, wvobj.m_ModelFitted, 'Raw abp Signal, FAILED', 'obj.m_Wave (Normalized)', ...
                'obj.m_ModelFitted (Gaussian)');
        end
        drawnow;    
    end
end