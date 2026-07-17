/* MemoX — Search local: ResultRow (term + meaning + deck + status badge).
   Composes the shared window.StatusCardRow (_shared/StatusCardRow.jsx); search adds
   the `deck` line and keeps the default (untightened, non-clipped) term/meaning. */
(function () {

function ResultRow(props) {
  return <window.StatusCardRow {...props} />;
}

window.MemoXSearch = window.MemoXSearch || {};
window.MemoXSearch.ResultRow = ResultRow;
})();

/* ESM export so the design-system compiler indexes this kit composite.
   The kit page itself loads this file via <script type="text/babel"> (with an
   `exports` shim in index.html) and reads it from the window registry above. */
export const ResultRow = (window.MemoXSearch || {}).ResultRow;
