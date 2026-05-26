// ============================================================
// integration.sci  —  Student C Module  [INTEGRATION COPY]
// Goodness-of-Fit Metrics and Failure-Hour Prediction
//
//NAME: Carlo Jane A. Branggan
//ID: 2024-0413
// You must implement TWO functions in this file.
// Do NOT change the function signatures.
//
// FORBIDDEN: Do NOT use Scilab's built-in fsolve(), roots(), or any
// root-finding builtin for find_threshold_hour.  Implement bisection
// from scratch as described in the manual.
// ============================================================

funcprot(0);   // suppress redefinition warnings when re-running

// ------------------------------------------------------------
// Function 1: goodness_of_fit
//
// Computes two model-accuracy metrics: RMSE and R².
//
// Input:
//   y_actual - vector of observed (measured) values    (n)
//   y_pred   - vector of model-predicted values        (n)
//
// Output:
//   rmse - Root-Mean-Square Error  (scalar, lower = better)
//   r2   - Coefficient of Determination  (scalar, closer to 1 = better)
//
// Hints:
//   - RMSE measures the typical size of prediction errors.  Start by
//     computing each residual (actual minus predicted), then build the
//     "root mean square" from those residuals.
//   - R² compares your model's total squared error against the baseline
//     error of simply predicting the mean of y_actual.  Write out both
//     sums explicitly before coding them.
//   - Consider what R² should equal when all observed values are identical
//     (SS_tot = 0) and handle that case explicitly.
// HOW TO USE THIS FILE:
//   1. Develop and test your code in  StudentC/integration.sci
//   2. When ready to run the test suite, COPY your finished
//      implementation into THIS file (replace the stubs below).
//   3. Run:  exec('test_suites/test_studentC.sci', -1)
//      from the phm_project/ directory.
// ============================================================
// ============================================================================
// Function 1: goodness_of_fit
// Inputs:  y_actual (vector), y_pred (vector)
// Outputs: rmse (scalar), r2 (scalar)
// ============================================================================
// ============================================================
// integration.sci  —  Student C Solution
// Goodness-of-Fit Metrics and Failure-Hour Prediction
// ============================================================
funcprot(0);   // suppress redefinition warnings when re-running

// ------------------------------------------------------------
// Function 1: goodness_of_fit
// ------------------------------------------------------------
function [rmse, r2]=goodness_of_fit(y_actual, y_pred)

    // TODO: validate that y_actual and y_pred have the same length
    if length(y_actual) <> length(y_pred) then
        error("Input vectors y_actual and y_pred must have the same length.");
    end

    // TODO: ensure column vectors
    y_actual = y_actual(:);
    y_pred = y_pred(:);

    // TODO: compute residuals
    residuals = y_actual - y_pred;

    // TODO: compute RMSE
    n = length(y_actual);
    rmse = sqrt(sum(residuals.^2) / n);

    // TODO: compute SS_res and SS_tot
    mean_actual = mean(y_actual);
    ss_res = sum(residuals.^2);
    ss_tot = sum((y_actual - mean_actual).^2);

    // TODO: compute r2 = 1 - SS_res / SS_tot  (handle SS_tot == 0)
    if ss_tot == 0 then
        if ss_res == 0 then
            r2 = 1.0;  // Perfect match for a completely constant dataset
        else
            r2 = 0.0;  // Constant dataset but model predictions vary/miss
        end
    else
        r2 = 1.0 - (ss_res / ss_tot);
    end

endfunction

// ------------------------------------------------------------
// Function 2: find_threshold_hour
// ------------------------------------------------------------
function [h_star]=find_threshold_hour(hours, vib_fit, threshold)

    // TODO: force column vectors;  n = length(hours);
    hours = hours(:);
    vib_fit = vib_fit(:);
    n = length(hours);

    // ---- Step 1: find the bracket ----
    i_lo = 0;
    for i = 1:(n-1)
        if (vib_fit(i) - threshold) * (vib_fit(i+1) - threshold) <= 0 then
            i_lo = i;
            break;
        end
    end

    // ---- Step 2: handle no-crossing case ----
    if i_lo == 0 then
        if vib_fit(n) < threshold then
            h_star = %inf;
            return;
        else
            h_star = hours(1); // Already exceeded at start
            return;
        end
    end

    // ---- Step 3: set up bracket endpoints ----
    h_lo = hours(i_lo);
    h_hi = hours(i_lo+1);
    
    g_lo = vib_fit(i_lo) - threshold;
    g_hi = vib_fit(i+1) - threshold;

    // ---- Step 4: bisection loop ----
    for iter = 1:100
        // Stop when the bracket width is less than 0.5 h
        if (h_hi - h_lo) < 0.5 then
            break;
        end
        
        // Compute the midpoint hour
        h_mid = (h_lo + h_hi) / 2;
        
        // Estimate g at h_mid by linear interpolation between the two known g-values
        // Equation: g_mid = g_lo + (h_mid - h_lo) * (g_hi - g_lo) / (h_hi - h_lo)
        g_mid = g_lo + (h_mid - h_lo) * (g_hi - g_lo) / (h_hi - h_lo);
        
        // Shrink the bracket based on the sign change
        if (g_lo * g_mid) <= 0 then
            h_hi = h_mid;
            g_hi = g_mid;
        else
            h_lo = h_mid;
            g_lo = g_mid;
        end
    end

    // TODO: return h_star as the midpoint of the final bracket.
    h_star = (h_lo + h_hi) / 2;

endfunction
