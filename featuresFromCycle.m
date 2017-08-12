function [sig, features, pass] = featuresFromCycle(wvobj, sig, DEBUG)
%%Function to extract features from a single sig cycle. Return features in
% featuress and pass flag indication if the sig passes the two Gaussian fitting
% criteria
    %DEBUG = true;

    %wvobj = WaveParameters();
    wvobj.deTrend(sig, true);
    wvobj.setWave(wvobj.m_Wave, 'normalize');
    [features,pass] = wvobj.qualifyCycles(wvobj.m_SamplingFrequency, 2);
    if(pass)
        sig = wvobj.m_Wave;
    end
    

    if(DEBUG)
        if(pass == 1)
            fitStr = ['Model error = ', num2str(wvobj.m_ModelError)];
            plotmulti(3, sig, wvobj.m_Wave, wvobj.m_ModelFitted, ['Raw sig Signal, PASS with ' fitStr], 'obj.m_Wave (Normalized)', ...
                'obj.m_ModelFitted (Gaussian)', 10001);
        else
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
            plotmulti(3, sig,  wvobj.m_Wave, wvobj.m_ModelFitted, ['Raw sig Signal, FAILED:', errMsg],  'obj.m_Wave (Normalized)', ...
                'obj.m_ModelFitted (Gaussian)', 10000);
        end
        drawnow;    
    end
end